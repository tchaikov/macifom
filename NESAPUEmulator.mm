/*
 *  NESAPUEmulator.mm
 *
 * Copyright (c) 2010 Auston Stewart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "NESAPUEmulator.h"
#import "NES6502Interpreter.h"

static int dmc_read_function( void* memoryReader, cpu_addr_t cpuAddress)
{
	NESMemoryReader *memoryReadStructure = (NESMemoryReader *)memoryReader;
	return memoryReadStructure->memoryReadFunction(memoryReadStructure->cpuInterpreter,@selector(readByteFromCPUAddressSpace:),(uint16_t)cpuAddress);
}

static void HandleOutputBuffer (
								void                *aqData,
								AudioQueueRef       inAQ,
								AudioQueueBufferRef inBuffer
) {
	// UInt32 bytesToRead;
	UInt32 bytesRead = 0;
	UInt32 samplesRead;
	UInt32 availableSamples;
    NESAPUState *pAqData = (NESAPUState *)aqData;
   
	// NSLog(@"In HandleOutputBuffer");
	
	if (!pAqData->isRunning) {
		
		bytesRead = pAqData->bufferByteSize;
		bzero(inBuffer->mAudioData,pAqData->bufferByteSize);
		// NSLog(@"NES APU is not running. Filling buffer with zeros.");	
	}
	else {
		
		availableSamples = pAqData->blipBuffer->samples_avail();
		// NSLog(@"%d samples available from blipBuffer",availableSamples);
		samplesRead = pAqData->blipBuffer->read_samples((blip_sample_t*)inBuffer->mAudioData,pAqData->numPacketsToRead);
		bytesRead = samplesRead * 2; // As each sample is 16-bits
		// NSLog(@"%d samples read from blipBuffer",samplesRead);
	}
			
	inBuffer->mAudioDataByteSize = bytesRead;
	AudioQueueEnqueueBuffer ( 
								pAqData->queue,
								inBuffer,
								0,
								NULL
								);
}


@implementation NESAPUEmulator

- (void)initializeAudioPlaybackQueue
{
	Float32 gain = 1.0;
	int error;
	
	// Create new output
	error = AudioQueueNewOutput (
								 &(nesAPUState->dataFormat),
								 HandleOutputBuffer,
								 nesAPUState,
								 CFRunLoopGetCurrent(),
								 kCFRunLoopCommonModes,
								 0,
								 &(nesAPUState->queue)
								 );
	
	NSLog(@"AudioQueueNewOutput: %d",error);
	
	// Set buffer size
	nesAPUState->numPacketsToRead = 2940; // 44.1kHz at 60 fps = 735 (times 4 to reduce overhead)
	nesAPUState->bufferByteSize = 5880; // 735 samples times four, times 16-bits per sample
	
	// Allocate those bufferes
	for (int i = 0; i < NUM_BUFFERS; ++i) {
		
		AudioQueueAllocateBuffer(
								 nesAPUState->queue,
								 nesAPUState->bufferByteSize,
								 &(nesAPUState->buffers[i])
								 );
		
		NSLog(@"AudioQueueAllocateBuffer: %d",error);
	}
	
	AudioQueueSetParameter (
							nesAPUState->queue,
							kAudioQueueParam_Volume,
							gain
							);
}

- (blip_time_t) clock { 

	return time += 4; 
}

- (id)init {

	if ([super init]) {
		
		time = 0;
		frame_length = 29780;
		
		nesAPU = new Nes_Apu();
		blipBuffer = new Blip_Buffer();
		blipBuffer->clock_rate( 1789773 ); // Should be 1789773 for NES
		blargg_err_t error = blipBuffer->sample_rate( 44100,600);
		if (error) NSLog(@"Error allocating blipBuffer.");
		
		nesAPU->output(blipBuffer);
		nesAPUState = (NESAPUState *)malloc(sizeof(NESAPUState));
		nesAPUState->dataFormat.mSampleRate = 44100.0;
		nesAPUState->dataFormat.mFormatID = kAudioFormatLinearPCM;
		
		// Sort out endianness
		if (NSHostByteOrder() == NS_BigEndian)
			nesAPUState->dataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		else
			nesAPUState->dataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		
		nesAPUState->dataFormat.mBytesPerPacket = 2;
		nesAPUState->dataFormat.mFramesPerPacket = 1;
		nesAPUState->dataFormat.mBytesPerFrame = 2;
		nesAPUState->dataFormat.mChannelsPerFrame = 1;
		nesAPUState->dataFormat.mBitsPerChannel = 16;
		nesAPUState->isRunning = NO;
		nesAPUState->bufferFillDelay = 2;
		
		nesAPUState->blipBuffer = blipBuffer;
		
		[self initializeAudioPlaybackQueue];
	}
	
	return self;
}

- (void)dealloc
{
	// Kill the queue and its buffers
	AudioQueueDispose (
					   nesAPUState->queue,
					   true
					   );
	
	// FIXME: Free NES APU Resources
	
	[super dealloc];
}

- (void)pause
{
	nesAPUState->isRunning = NO;
	AudioQueuePause(nesAPUState->queue);
}

- (void)resume
{
	if (!nesAPUState->bufferFillDelay) nesAPUState->isRunning = YES;
	AudioQueueStart(nesAPUState->queue,NULL);
}

- (void)stopAPUPlayback
{
	nesAPUState->isRunning = NO;
	AudioQueueStop (nesAPUState->queue,true);
}

- (void)beginAPUPlayback
{
	nesAPUState->isRunning = NO;
	nesAPUState->bufferFillDelay = 4;
	
	// Prime the playback buffer
	for (int i = 0; i < NUM_BUFFERS; ++i) {
		
		HandleOutputBuffer (
							nesAPUState,
							nesAPUState->queue,
							nesAPUState->buffers[i]
							);
	}
}

// Set function for APU to call when it needs to read memory (DMC samples)
-(void)setDMCReadObject:(NES6502Interpreter *)cpu {

	NESMemoryReader *dmcUserData = (NESMemoryReader *)malloc(sizeof(NESMemoryReader));
	dmcUserData->cpuInterpreter = cpu;
	dmcUserData->memoryReadFunction = (uint8_t (*)(id, SEL, uint16_t))[cpu methodForSelector:@selector(readByteFromCPUAddressSpace:)];
	nesAPU->dmc_reader(dmc_read_function,dmcUserData);
}

// Set output sample rate
- (BOOL)setOutputSampleRate:(long)rate {

	// simpleApu.sample_rate(rate);
	
	return YES;
}

// Write to register (0x4000-0x4017, except 0x4014 and 0x4016)
- (void)writeByte:(uint8_t)byte toAPUFromCPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle {

	nesAPU->write_register(cycle, address, byte);
}

// Read from status register at 0x4015
- (uint8_t)readAPUStatusOnCycle:(uint_fast32_t)cycle {

	return nesAPU->read_status(cycle);
}

// End a 1/60 sound frame
- (double)endFrameOnCycle:(uint_fast32_t)cycle {

	UInt32 availableSamples;
	double timingCorrection = 0;
	nesAPU->end_frame(cycle);
	blipBuffer->end_frame(cycle);
	
	if (nesAPUState->bufferFillDelay > 0) nesAPUState->bufferFillDelay--;
	else {
		
		nesAPUState->isRunning = YES;
		availableSamples = nesAPUState->blipBuffer->samples_avail();
		if (availableSamples < (nesAPUState->numPacketsToRead * 2)) {
			
			timingCorrection = -0.005;
		}
		else if (availableSamples > (nesAPUState->numPacketsToRead * 4)) {
			
			timingCorrection = 0.005;
		}
	}
	
	return timingCorrection;
}

// Number of samples in buffer
- (long)numberOfBufferedSamples {
	
	return blipBuffer->samples_avail();
}

// Save/load snapshot of emulation state
- (void)saveSnapshot {

}

- (void)loadSnapshot {
	
}

@end