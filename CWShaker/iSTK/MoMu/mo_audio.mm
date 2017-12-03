
/*----------------------------------------------------------------------------
  MoMu: A Mobile Music Toolkit
  Copyright (c) 2010 Nicholas J. Bryan, Jorge Herrera, Jieun Oh, and Ge Wang
  All rights reserved.
    http://momu.stanford.edu/toolkit/
 
  Mobile Music Research @ CCRMA
  Music, Computing, Design Group
  Stanford University
    http://momu.stanford.edu/
    http://ccrma.stanford.edu/groups/mcd/
 
 MoMu is distributed under the following BSD style open source license:
 
 Permission is hereby granted, free of charge, to any person obtaining a 
 copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The authors encourage users of MoMu to include this copyright notice,
 and to let us know that you are using MoMu. Any person wishing to 
 distribute modifications to the Software is encouraged to send the 
 modifications to the original authors so that they can be incorporated 
 into the canonical version.
 
 The Software is provided "as is", WITHOUT ANY WARRANTY, express or implied,
 including but not limited to the warranties of MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE and NONINFRINGEMENT.  In no event shall the authors
 or copyright holders by liable for any claim, damages, or other liability,
 whether in an actino of a contract, tort or otherwise, arising from, out of
 or in connection with the Software or the use or other dealings in the 
 software.
 -----------------------------------------------------------------------------*/
//-----------------------------------------------------------------------------
// name: mo_audio.cpp
// desc: MoPhO audio layer
//       - adapted from the smule audio layer & library (SMALL)
//         (see original header below)
//
// authors: Ge Wang (ge@ccrma.stanford.edu | ge@smule.com)
//          Spencer Salazar (spencer@smule.com)
//    date: October 2009
//    version: 1.0.0
//
// Mobile Music research @ CCRMA, Stanford University:
//     http://momu.stanford.edu/
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// name: small.cpp (original)
// desc: the smule audio layer & library (SMALL)
//
// created by Ge Wang on 6/27/2008
// re-implemented using Audio Unit Remote I/O on 8/12/2008
// updated for iPod Touch by Spencer Salazar and Ge wang on 8/10/2009
//-----------------------------------------------------------------------------

#define Check(expr) do { OSStatus err = (expr); if (err) { NSLog(@"error %d from %s", (int)err, #expr); exit(1); } } while (0)
#define NSCheck(expr) do { NSError *err = nil; if (!(expr)) { NSLog(@"error from %s: %@", #expr, err);  exit(1); } } while (0)

#include "mo_audio.h"
#include <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CWAudioHandler.h"

// static member initialization
bool MoAudio::m_hasInit = false;
bool MoAudio::m_isRunning = false;
bool MoAudio::m_isMute = false;
bool MoAudio::m_handleInput = false;
Float64 MoAudio::m_srate = 44100.0;
Float64 MoAudio::m_hwSampleRate = 44100.0;
UInt32 MoAudio::m_frameSize = 0;
UInt32 MoAudio::m_numChannels = 2;
AudioUnit MoAudio::m_au;
MoAudioUnitInfo * MoAudio::m_info = NULL;
MoCallback MoAudio::m_callback = NULL;
// Float32 * MoAudio::m_buffer = NULL;
// UInt32 MoAudio::m_bufferFrames = 2048;
AURenderCallbackStruct MoAudio::m_renderProc;
void * MoAudio::m_bindle = NULL;

// number of buffers
#define MO_DEFAULT_NUM_BUFFERS   3

// prototypes
bool setupRemoteIO( AudioUnit & inRemoteIOUnit, AURenderCallbackStruct inRenderProc,
                    AudioStreamBasicDescription & outFormat);


//-----------------------------------------------------------------------------
// name: silenceData()
// desc: zero out a buffer list of audio data
//-----------------------------------------------------------------------------
void silenceData( AudioBufferList * inData )
{
    for( UInt32 i = 0; i < inData->mNumberBuffers; i++ )
        memset( inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize );
}




//-----------------------------------------------------------------------------
// name: convertToUser()
// desc: convert to user data (stereo)
//-----------------------------------------------------------------------------
void convertToUser( AudioBufferList * inData, Float32 * buffy, 
                    UInt32 numFrames, UInt32 & actualFrames )
{
    // make sure there are exactly two channels
    assert( inData->mNumberBuffers == MoAudio::m_numChannels );
    // get number of frames
    UInt32 inFrames = inData->mBuffers[0].mDataByteSize / sizeof(SInt32);
    // make sure enough space
    assert( inFrames <= numFrames );
    // channels
    SInt32 * left = (SInt32 *)inData->mBuffers[0].mData;
    SInt32 * right = (SInt32 *)inData->mBuffers[1].mData;
    // fixed to float scaling factor
    Float32 factor = (Float32)(1 << 24);
    // interleave (AU is by default non interleaved)
    for( UInt32 i = 0; i < inFrames; i++ )
    {
        // convert (AU is by default 8.24 fixed)
        buffy[2*i] = ((Float32)left[i]) / factor;
        buffy[2*i+1] = ((Float32)right[i]) / factor;
    }
    // return
    actualFrames = inFrames;
}




//-----------------------------------------------------------------------------
// name: convertFromUser()
// desc: convert from user data (stereo)
//-----------------------------------------------------------------------------
void convertFromUser( AudioBufferList * inData, Float32 * buffy, UInt32 numFrames )
{
    // make sure there are exactly two channels
    assert( inData->mNumberBuffers == MoAudio::m_numChannels );
    // get number of frames
    UInt32 inFrames = inData->mBuffers[0].mDataByteSize / 4;
    // make sure enough space
    assert( inFrames <= numFrames );
    // channels
    SInt32 * left = (SInt32 *)inData->mBuffers[0].mData;
    SInt32 * right = (SInt32 *)inData->mBuffers[1].mData;
    // fixed to float scaling factor
    Float32 factor = (Float32)(1 << 24);
    // interleave (AU is by default non interleaved)
    for( UInt32 i = 0; i < inFrames; i++ )
    {
        // convert (AU is by default 8.24 fixed)
        left[i] = (SInt32)(buffy[2*i] * factor);
        right[i] = (SInt32)(buffy[2*i+1] * factor);
    }
}




//-----------------------------------------------------------------------------
// name: SMALLRenderProc()
// desc: callback procedure awaiting audio unit audio buffers
//-----------------------------------------------------------------------------
static OSStatus SMALLRenderProc(
    void * inRefCon, 
    AudioUnitRenderActionFlags * ioActionFlags, 
    const AudioTimeStamp * inTimeStamp, 
    UInt32 inBusNumber, 
    UInt32 inNumberFrames, 
    AudioBufferList * ioData ) 
{
    OSStatus err = noErr;

    // render if full-duplex available and enabled
    if( MoAudio::m_handleInput ) {
        
        Check(AudioUnitRender( MoAudio::m_au, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData ));
    }

    // actual frames
    UInt32 actualFrames = 0;
    
    // convert
    convertToUser( ioData, MoAudio::m_info->m_ioBuffer, MoAudio::m_info->m_bufferSize, actualFrames );
    
    // callback
    MoAudio::m_callback( MoAudio::m_info->m_ioBuffer, actualFrames, MoAudio::m_bindle );
    
    // convert back
    convertFromUser( ioData, MoAudio::m_info->m_ioBuffer, MoAudio::m_info->m_bufferSize );
    
    // mute?
    if( MoAudio::m_isMute )
    { silenceData( ioData ); }
    
    return err;
}


//-----------------------------------------------------------------------------
// name: setupRemoteIO()
// desc: setup Audio Unit Remote I/O
//-----------------------------------------------------------------------------
bool setupRemoteIO( AudioUnit & inRemoteIOUnit, AURenderCallbackStruct inRenderProc,
                    AudioStreamBasicDescription & outFormat ) {
    // open the output unit
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    // find next component
    AudioComponent comp = AudioComponentFindNext( NULL, &desc );
    
    // the stream description
    AudioStreamBasicDescription localFormat;
    
    // open remote I/O unit
    Check(AudioComponentInstanceNew( comp, &inRemoteIOUnit ));

//    UInt32 one = 1;
    // enable input
//    Check(AudioUnitSetProperty( inRemoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one) ));

    // set render proc
    Check(AudioUnitSetProperty( inRemoteIOUnit, kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Input, 0, &inRenderProc, sizeof(inRenderProc) ));
        
    UInt32 size = sizeof(localFormat);
    // get and set client format
    Check(AudioUnitGetProperty( inRemoteIOUnit, kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input, 0, &localFormat, &size ));

    localFormat.mSampleRate = outFormat.mSampleRate;
    localFormat.mChannelsPerFrame = outFormat.mChannelsPerFrame;
    
    localFormat.mFormatID = outFormat.mFormatID;
    localFormat.mSampleRate = outFormat.mSampleRate;
    localFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved | (24 << kLinearPCMFormatFlagsSampleFractionShift);
    localFormat.mChannelsPerFrame = outFormat.mChannelsPerFrame;
    localFormat.mBitsPerChannel = 32;
    localFormat.mFramesPerPacket = 1;
    localFormat.mBytesPerFrame = 4;
    localFormat.mBytesPerPacket = 4;
    localFormat.mReserved = 0;
    
    // set stream property
    Check(AudioUnitSetProperty( inRemoteIOUnit, kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input, 0, &localFormat, sizeof(localFormat) ));
    
    size = sizeof(outFormat);
    // get it again
    Check(AudioUnitGetProperty( inRemoteIOUnit, kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input, 0, &outFormat, &size ));
    Check(AudioUnitSetProperty( inRemoteIOUnit, kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Output, 1, &outFormat, sizeof(outFormat) ));

    Check(AudioUnitInitialize( inRemoteIOUnit ));

    return true;
}




//-----------------------------------------------------------------------------
// name: init()
// desc: initialize the MoAudio
//-----------------------------------------------------------------------------
bool MoAudio::init( Float64 srate, UInt32 frameSize, UInt32 numChannels ) {
    
    if( m_hasInit ) {
        DLog(@"Already inited MoAudio, can't init again!");
        return false;
    }
    
    // set audio unit callback
    m_renderProc.inputProc = SMALLRenderProc;
    m_renderProc.inputProcRefCon = NULL;
    
    m_info = new MoAudioUnitInfo();

    // set the desired data format
    m_info->m_dataFormat.mSampleRate = srate;
    m_info->m_dataFormat.mFormatID = kAudioFormatLinearPCM;
    m_info->m_dataFormat.mChannelsPerFrame = numChannels;
    m_info->m_dataFormat.mBitsPerChannel = 32;
    m_info->m_dataFormat.mBytesPerPacket = m_info->m_dataFormat.mBytesPerFrame =
    m_info->m_dataFormat.mChannelsPerFrame * sizeof(SInt32);
    m_info->m_dataFormat.mFramesPerPacket = 1;
    m_info->m_dataFormat.mReserved = 0;
    m_info->m_dataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    m_info->m_done = 0;

    // bound parameters
    if (frameSize > m_info->m_bufferSize)
        frameSize = m_info->m_bufferSize;
    
    // why?
    numChannels = 2;
    
    // copy parameters
    m_srate = srate;
    m_frameSize = frameSize;
    m_numChannels = numChannels;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];

    [[NSNotificationCenter defaultCenter] addObserver:[CWAudioHandler sharedHandler] selector:@selector(audioSessionDidChangeInterruptionType:) name:AVAudioSessionInterruptionNotification object:audioSession];
    
    NSError *error = nil;
    
    // AVAudioSessionCategoryAmbient = silenced by mute switch
    NSCheck([audioSession setCategory:AVAudioSessionCategoryPlayback error:&error]);
    
    Float32 preferredBufferSize = (Float32)(frameSize / srate); // .020;
    NSCheck([audioSession setPreferredIOBufferDuration:preferredBufferSize error:&error]);

    NSCheck([audioSession setPreferredSampleRate:(double)srate error:&error]);
    
    NSCheck([audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error]);
    
    NSCheck([audioSession setActive:YES error:&error]);
    
    MoAudio::m_hwSampleRate = [audioSession sampleRate];
    
    if( !setupRemoteIO( m_au, m_renderProc, m_info->m_dataFormat ) ) {
        DLog(@"couldn't setup remote i/o unit");
        return false;
    }
    
    // initialize buffer
    m_info->m_ioBuffer = new Float32[m_info->m_bufferSize * m_numChannels];
    // make sure
    if( !m_info->m_ioBuffer ) {
        DLog(@"couldn't allocate memory for I/O buffer");
        return false;
    }
    
    checkInput();
    m_hasInit = true;

    return true;
}


//-----------------------------------------------------------------------------
// name: start()
// desc: start the MoAudio
//-----------------------------------------------------------------------------
bool MoAudio::start( MoCallback callback, void * bindle ) {
    
    assert( callback != NULL );

    if( !m_hasInit || m_isRunning) {
        return false;
    }
    
    m_callback = callback;
    m_bindle = bindle;

    Check(AudioOutputUnitStart( m_au ));
    
    m_isRunning = true;

    return true;
}


//-----------------------------------------------------------------------------
// name: stop()
// desc: stop the MoAudio
//-----------------------------------------------------------------------------
void MoAudio::stop() {

    if( !m_isRunning )
        return;
    
    Check(AudioOutputUnitStop( m_au ));

    m_isRunning = false;
}


//-----------------------------------------------------------------------------
// name: shutdown()
// desc: shutdown the MoAudio
//-----------------------------------------------------------------------------
void MoAudio::shutdown() {
    
    if( !m_hasInit )
        return;

    stop();
    
    m_hasInit = false;
    m_callback = NULL;
    
    SAFE_DELETE( m_info );
}


//-----------------------------------------------------------------------------
// name: checkInput()
// desc: check audio input, and sets appropriate flag
//-----------------------------------------------------------------------------
void MoAudio::checkInput() {
    
//    m_handleInput = true;
//
//    bool has_input = [[AVAudioSession sharedInstance] isInputAvailable];
//    
//    if( !has_input  ) {
//        DLog(@"warning: full duplex enabled without available input");
        m_handleInput = false;
//    }
}


//------------------------------------------------------------------------------
// name: vibrate()
// desc: trigger vibration
//------------------------------------------------------------------------------
void MoAudio::vibrate() {
    
    AudioServicesPlaySystemSound( kSystemSoundID_Vibrate );
}
