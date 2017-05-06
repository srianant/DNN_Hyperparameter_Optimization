//--------------------------------------------------------------------------------------
// File: wavdump.cpp
//
// WAV file content examination utility
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

#include <windows.h>

#include <stdio.h>
#include <mmsystem.h>
#include <mmreg.h>
#include <ks.h>
#include <ksmedia.h>
#include <memory>
#include <x3daudio.h>

#pragma comment(lib,"winmm.lib")

#if !defined(WAVE_FORMAT_XMA2)
#define WAVE_FORMAT_XMA2 0x166

#pragma pack(push,1)
typedef struct XMA2WAVEFORMATEX
{
    WAVEFORMATEX wfx;
    // Meaning of the WAVEFORMATEX fields here:
    //    wFormatTag;        // Audio format type; always WAVE_FORMAT_XMA2
    //    nChannels;         // Channel count of the decoded audio
    //    nSamplesPerSec;    // Sample rate of the decoded audio
    //    nAvgBytesPerSec;   // Used internally by the XMA encoder
    //    nBlockAlign;       // Decoded sample size; channels * wBitsPerSample / 8
    //    wBitsPerSample;    // Bits per decoded mono sample; always 16 for XMA
    //    cbSize;            // Size in bytes of the rest of this structure (34)

    WORD  NumStreams;        // Number of audio streams (1 or 2 channels each)
    DWORD ChannelMask;       // Spatial positions of the channels in this file,
                             // stored as SPEAKER_xxx values (see audiodefs.h)
    DWORD SamplesEncoded;    // Total number of PCM samples per channel the file decodes to
    DWORD BytesPerBlock;     // XMA block size (but the last one may be shorter)
    DWORD PlayBegin;         // First valid sample in the decoded audio
    DWORD PlayLength;        // Length of the valid part of the decoded audio
    DWORD LoopBegin;         // Beginning of the loop region in decoded sample terms
    DWORD LoopLength;        // Length of the loop region in decoded sample terms
    BYTE  LoopCount;         // Number of loop repetitions; 255 = infinite
    BYTE  EncoderVersion;    // Version of XMA encoder that generated the file
    WORD  BlockCount;        // XMA blocks in file (and entries in its seek table)
} XMA2WAVEFORMATEX;
#pragma pack(pop)
#endif

static_assert(sizeof(XMA2WAVEFORMATEX) == 52, "Mismatch of XMA2 type" );

class ScopedMMHandle
{
public:
    explicit ScopedMMHandle( HMMIO handle ) : _handle(handle) {}
    ~ScopedMMHandle()
    {
        if ( _handle != 0 )
        {
            mmioClose( _handle, 0 );
            _handle = 0;
        }
    }

    bool IsValid() const { return (_handle != 0); }
    HMMIO Get() const { return _handle; }

private:
    HMMIO _handle;
};


const char* GetFormatTagName( WORD wFormatTag )
{
    switch( wFormatTag )
    {
    case WAVE_FORMAT_PCM: return "PCM";
    case WAVE_FORMAT_ADPCM: return "MS ADPCM";
    case WAVE_FORMAT_EXTENSIBLE: return "EXTENSIBLE";
    case WAVE_FORMAT_IEEE_FLOAT: return "IEEE float";
    case WAVE_FORMAT_MPEGLAYER3: return "ISO/MPEG Layer3";
    case WAVE_FORMAT_DOLBY_AC3_SPDIF: return "Dolby Audio Codec 3 over S/PDIF";
    case WAVE_FORMAT_WMAUDIO2: return "Windows Media Audio";
    case WAVE_FORMAT_WMAUDIO3: return "Windows Media Audio Pro";
    case WAVE_FORMAT_WMASPDIF: return "Windows Media Audio over S/PDIF";
    case 0x165: /*WAVE_FORMAT_XMA*/ return "Xbox 360 XMA";
    case WAVE_FORMAT_XMA2: return "Xbox 360/Xbox One XMA2";
    default: return "*UNKNOWN*";
    }
}

const char *ChannelDesc( DWORD dwChannelMask )
{
    switch( dwChannelMask )
    {
    case SPEAKER_MONO: return "Mono";
    case SPEAKER_STEREO: return "Stereo";
    case SPEAKER_2POINT1: return "2.1";
    case SPEAKER_SURROUND: return "Surround";
    case SPEAKER_QUAD: return "Quad";
    case SPEAKER_4POINT1: return "4.1";
    case SPEAKER_5POINT1: return "5.1";
    case SPEAKER_7POINT1: return "7.1";
    case SPEAKER_5POINT1_SURROUND: return "Surround5.1";
    case SPEAKER_7POINT1_SURROUND: return "Surround7.1";
    default: return "Custom";
    }
}

int main(int argc, const char** argv)
{
    if ( argc < 2 || argc > 2 )
    {
        printf("Usage: wavdump <filename.wav>\n");
        return 0;
    }

    ScopedMMHandle h( mmioOpen( (LPSTR)argv[1], nullptr, MMIO_ALLOCBUF | MMIO_READ ) );
    if ( !h.IsValid() )
    {
        printf("Failed opening %s\n", argv[1] );
        return 1;
    }

    // Validate file is a WAVE
    MMCKINFO riff;
    memset( &riff, 0, sizeof(riff) );

    if ( mmioDescend( h.Get(), &riff, nullptr, 0 ) != MMSYSERR_NOERROR )
    {
        printf("Failed validating file %s\n", argv[1] );
        return 1;
    }

    if ( (riff.ckid != FOURCC_RIFF)
         || ( ( riff.fccType != mmioFOURCC( 'W', 'A', 'V','E' ) ) && ( riff.fccType != mmioFOURCC( 'X', 'W', 'M','A' ) ) ) )
    {
        printf("Not a wave file: %s\n", argv[1] );
        return 1;
    }

    bool xwma = riff.fccType == mmioFOURCC( 'X', 'W', 'M','A' );

    std::unique_ptr<BYTE> chunk;

    // find 'fmt ' chunk
    MMCKINFO c;
    memset( &c, 0, sizeof(c) );

    c.ckid = mmioFOURCC( 'f', 'm', 't', ' ' );
    if ( mmioDescend( h.Get(), &c, &riff, MMIO_FINDCHUNK ) != MMSYSERR_NOERROR )
    {
        printf("Failed to find 'fmt ' chunk in wave file %s\n", argv[1] );
        return 1;
    }

    if ( c.cksize < sizeof( WAVEFORMAT ) )
    {
        printf("Header size is only %u bytes for wave file %s\n", c.cksize, argv[1] );
        return 1;
    }

    chunk.reset( new (std::nothrow) BYTE[c.cksize] );
    if ( !chunk )
    {
        printf("Out of memory loading %u bytes", c.cksize);
        return 1;
    }

    if ( (ULONG)mmioRead( h.Get(), (HPSTR)chunk.get(), c.cksize ) != c.cksize )
    {
        printf("Failed reading %u header bytes from wave file %s\n", c.cksize, argv[1] );
        return 1;
    }

    printf("WAVE file %s\n", argv[1] );
    printf("riff '%s', chunk 'fmt ', %u bytes\n", (xwma) ? "XWMA" : "WAVE", c.cksize);

    auto header = reinterpret_cast<const WAVEFORMAT*>( chunk.get() );

    printf("format tag %04u (%s)\n", header->wFormatTag, GetFormatTagName(header->wFormatTag) );

    printf("number of channels %u\n", header->nChannels );
    if ( header->nChannels < 1 || header->nChannels > 64 )
        printf("ERROR: Expected between 1..64 channels\n");

    printf("samples per second %u\n", header->nSamplesPerSec );
    if ( header->nSamplesPerSec < 1000 || header->nSamplesPerSec > 200000 )
        printf("ERROR: Expected between 1..200kHZ\n");

    printf("avg bytes per second %u\n", header->nAvgBytesPerSec );
    printf("sample block size %u bytes\n", header->nBlockAlign );

    switch( header->wFormatTag )
    {
    case WAVE_FORMAT_PCM:
    case WAVE_FORMAT_IEEE_FLOAT:
        if ( c.cksize < sizeof(PCMWAVEFORMAT) )
        {
            printf("Header is too small to be valid in wave file %s\n", argv[1] );
            return 1;
        }
        else if ( c.cksize < sizeof(WAVEFORMATEX) )
        {
            auto pcm = reinterpret_cast<const PCMWAVEFORMAT*>( chunk.get() );
            printf("bits per sample %u\n", pcm->wBitsPerSample );
        }
        else
        {
            auto wfx = reinterpret_cast<const WAVEFORMATEX*>( chunk.get() );
            printf("bits per sample %u\n", wfx->wBitsPerSample );
            printf("extra bytes %u\n", wfx->cbSize );
        }
        break;

    case WAVE_FORMAT_ADPCM:
        if ( c.cksize < sizeof(ADPCMWAVEFORMAT) )
        {
            printf("Header is too small to be valid in wave file %s\n", argv[1] );
            return 1;
        }
        else
        {
            auto adpcm = reinterpret_cast<const ADPCMWAVEFORMAT*>( chunk.get() );
            printf("bits per sample %u\n", adpcm->wfx.wBitsPerSample );
            printf("extra bytes %u\n", adpcm->wfx.cbSize );
            printf("samples per block %u\n", adpcm->wSamplesPerBlock );
            printf("number of coefficients %u\n", adpcm->wNumCoef );
            if ( adpcm->wNumCoef != 7 )
               printf("ERROR: MS ADPCM expected to have 7 coefficients\n");
        }
        break;

    case WAVE_FORMAT_XMA2:
        if ( c.cksize < sizeof(XMA2WAVEFORMATEX) )
        {
            printf("Header is too small to be valid in wave file %s\n", argv[1] );
            return 1;
        }
        else
        {
            auto xma = reinterpret_cast<const XMA2WAVEFORMATEX*>( chunk.get() );
            printf("number of streams %u\n", xma->NumStreams );
            printf("xma channel mask %u (%s)\n", xma->ChannelMask, ChannelDesc( xma->ChannelMask ) );
            printf("samples encoded %u\n", xma->SamplesEncoded );
            printf("bytes per block %u\n", xma->BytesPerBlock );
            printf("play [%u, %u]\n", xma->PlayBegin, xma->PlayLength );
            printf("loop [%u, %u] %u\n", xma->LoopBegin, xma->LoopLength, xma->LoopCount );
            printf("encoder version %u\n", xma->EncoderVersion );
            printf("block count %u\n", xma->BlockCount );
        }
        break;

    case WAVE_FORMAT_EXTENSIBLE:
        if ( c.cksize < sizeof(WAVEFORMATEXTENSIBLE) )
        {
            printf("Header is too small to be valid in wave file %s\n", argv[1] );
            return 1;
        }
        else
        {
            auto ext = reinterpret_cast<const WAVEFORMATEXTENSIBLE*>( chunk.get() );
            printf("bits per sample %u\n", ext->Format.wBitsPerSample );
            printf("extra bytes %u\n", ext->Format.cbSize );
            printf("valid bits-per-sample / samples per block / reserved %u\n", ext->Samples.wReserved );
            printf("channel mask %08X (%s)\n", ext->dwChannelMask, ChannelDesc( ext->dwChannelMask ) );
            printf("Subformat GUID %08X-%04X-%04X-%02X%02X%02X%02X%02X%02X%02X%02X", ext->SubFormat.Data1, ext->SubFormat.Data2, ext->SubFormat.Data3, 
                   ext->SubFormat.Data4[0], ext->SubFormat.Data4[1], ext->SubFormat.Data4[2], ext->SubFormat.Data4[3], 
                   ext->SubFormat.Data4[4], ext->SubFormat.Data4[5], ext->SubFormat.Data4[6], ext->SubFormat.Data4[7] );

            static const GUID s_wfexBase = {0x00000000, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71};

            if ( memcmp( reinterpret_cast<const BYTE*>(&ext->SubFormat) + sizeof(DWORD),
                         reinterpret_cast<const BYTE*>(&s_wfexBase) + sizeof(DWORD), sizeof(GUID) - sizeof(DWORD) ) == 0 )
            {
                printf(" (%s)\n", GetFormatTagName( static_cast<WORD>(ext->SubFormat.Data1) ) );
            }
            else
                printf("\n");
        }
        break;

     default:
        if ( c.cksize < sizeof(WAVEFORMATEX) )
        {
            printf("Header is is too small for a WAVEFORMATEX in wave file %s\n", argv[1] );
            return 1;
        }
        else
        {
            auto wfx = reinterpret_cast<const WAVEFORMATEX*>( chunk.get() );
            printf("bits per sample %u\n", wfx->wBitsPerSample );
            printf("extra bytes %u\n", wfx->cbSize );
        }
        break;
    }

    if ( mmioAscend( h.Get(), &c, 0 ) != MMSYSERR_NOERROR )
    {
        printf("Failed to exit 'fmt ' chunk in wave file %s\n", argv[1] );
        return 1;
    }

    // find optional 'wsmp' chunk
    if ( mmioSeek( h.Get(), riff.dwDataOffset + 4, SEEK_SET ) == -1 )
    {
        printf("Failed to reset seek\n" );
        return 1;
    }

    MMCKINFO cwsmp;
    memset( &cwsmp, 0, sizeof(cwsmp) );

    cwsmp.ckid = mmioFOURCC( 'w', 's', 'm', 'p' );
    if ( mmioDescend( h.Get(), &cwsmp, &riff, MMIO_FINDCHUNK ) == MMSYSERR_NOERROR )
    {
        static const uint32_t LOOP_TYPE_FORWARD = 0x00000000;
        static const uint32_t LOOP_TYPE_RELEASE = 0x00000001;
        static const uint32_t OPTIONS_NOTRUNCATION = 0x00000001;
        static const uint32_t OPTIONS_NOCOMPRESSION = 0x00000002;

        struct DLSLoop
        {

            uint32_t size;
            uint32_t loopType;
            uint32_t loopStart;
            uint32_t loopLength;
        };

        struct DLSSample
        {
            uint32_t    size;
            uint16_t    unityNote;
            int16_t     fineTune;
            int32_t     gain;
            uint32_t    options;
            uint32_t    loopCount;
        };

        if ( cwsmp.cksize < sizeof( DLSSample ) )
        {
            printf("wsmp chunk size is only %u bytes\n", cwsmp.cksize );
            return 1;
        }

        chunk.reset( new (std::nothrow) BYTE[cwsmp.cksize] );
        if ( !chunk )
        {
            printf("Out of memory loading %u bytes", cwsmp.cksize);
            return 1;
        }

        if ( (ULONG)mmioRead( h.Get(), (HPSTR)chunk.get(), cwsmp.cksize ) != cwsmp.cksize )
        { 
            printf("Failed reading %u bytes of wsmp chunk from wave file %s\n", cwsmp.cksize, argv[1] );
            return 1;
        }

        auto dlsSample = reinterpret_cast<const DLSSample*>( chunk.get() );

        if ( cwsmp.cksize >= ( dlsSample->size + dlsSample->loopCount * sizeof(DLSLoop) ) )
        {
            printf( "Found DLS Sample WSMP chunk\n");

            printf("\tFound %u loop points\n", dlsSample->loopCount );
            auto loops = reinterpret_cast<const DLSLoop*>( chunk.get() + dlsSample->size );
            for( uint32_t j = 0; j < dlsSample->loopCount; ++j )
            {
                printf("\tType %u, start %u, length %u\n", loops[j].loopType, loops[j].loopStart, loops[j].loopLength );
            }
        }
        else
        {
            printf( "ERROR: Found DLS Sample WSMP chunk, but it's too small to be valid\n");
        }

        if ( mmioAscend( h.Get(), &cwsmp, 0 ) != MMSYSERR_NOERROR )
        {
            printf("Failed to exit 'wsmp' chunk in wave file %s\n", argv[1] );
            return 1;
        }
    }

    // find optional 'smpl' chunk
    if ( mmioSeek( h.Get(), riff.dwDataOffset + 4, SEEK_SET ) == -1 )
    {
        printf("Failed to reset seek\n" );
        return 1;
    }

    MMCKINFO csmpl;
    memset( &csmpl, 0, sizeof(csmpl) );

    csmpl.ckid = mmioFOURCC( 's', 'm', 'p', 'l' );
    if ( mmioDescend( h.Get(), &csmpl, &riff, MMIO_FINDCHUNK ) == MMSYSERR_NOERROR )
    {
        static const uint32_t LOOP_TYPE_FORWARD     = 0x00000000;
        static const uint32_t LOOP_TYPE_ALTERNATING = 0x00000001;
        static const uint32_t LOOP_TYPE_BACKWARD    = 0x00000002;

        struct MIDILoop
        {
            uint32_t cuePointId;
            uint32_t type;
            uint32_t start;
            uint32_t end;
            uint32_t fraction;
            uint32_t playCount;
        };

        struct MIDISample
        {
            uint32_t        manufacturerId;
            uint32_t        productId;
            uint32_t        samplePeriod;
            uint32_t        unityNode;
            uint32_t        pitchFraction;
            uint32_t        SMPTEFormat;
            uint32_t        SMPTEOffset;
            uint32_t        loopCount;
            uint32_t        samplerData;
        };

        if ( csmpl.cksize < sizeof( MIDISample ) )
        {
            printf("smpl chunk size is only %u bytes\n", csmpl.cksize );
            return 1;
        }

        chunk.reset( new (std::nothrow) BYTE[csmpl.cksize] );
        if ( !chunk )
        {
            printf("Out of memory loading %u bytes", csmpl.cksize);
            return 1;
        }

        if ( (ULONG)mmioRead( h.Get(), (HPSTR)chunk.get(), csmpl.cksize ) != csmpl.cksize )
        { 
            printf("Failed reading %u bytes of smpl chunk from wave file %s\n", csmpl.cksize, argv[1] );
            return 1;
        }

        auto midiSample = reinterpret_cast<const MIDISample*>( chunk.get() );

        if ( csmpl.cksize >= ( sizeof(MIDISample) + midiSample->loopCount * sizeof(MIDILoop) ) )
        {
            printf( "Found MIDI Sample SMPL chunk\n");
            printf("\tFound %u loop points\n", midiSample->loopCount );
            auto loops = reinterpret_cast<const MIDILoop*>( chunk.get() + sizeof(MIDISample) );
            for( uint32_t j = 0; j < midiSample->loopCount; ++j )
            {
                printf("\tType %u, start %u, end %u\n", loops[j].type, loops[j].start, loops[j].end );
            }
        }
        else
        {
            printf( "ERROR: Found MIDI Sample SMPL chunk, but it's too small to be valid\n");
        }

        if ( mmioAscend( h.Get(), &csmpl, 0 ) != MMSYSERR_NOERROR )
        {
            printf("Failed to exit 'smpl' chunk in wave file %s\n", argv[1] );
            return 1;
        }
    }

    // find optional 'dpds' chunk
    if ( mmioSeek( h.Get(), riff.dwDataOffset + 4, SEEK_SET ) == -1 )
    {
        printf("Failed to reset seek\n" );
        return 1;
    }

    MMCKINFO cdpds;
    memset( &cdpds, 0, sizeof(cdpds) );

    cdpds.ckid = mmioFOURCC( 'd', 'p', 'd', 's' );
    if ( mmioDescend( h.Get(), &cdpds, &riff, MMIO_FINDCHUNK ) == MMSYSERR_NOERROR )
    {
        printf("chunk 'dpds', %u bytes", cdpds.cksize);

        if ( cdpds.cksize > 0 )
        {
            chunk.reset( new (std::nothrow) BYTE[cdpds.cksize] );
            if ( !chunk )
            {
                printf("\nOut of memory loading %u bytes", cdpds.cksize);
                return 1;
            }

            if ( (ULONG)mmioRead( h.Get(), (HPSTR)chunk.get(), cdpds.cksize ) != cdpds.cksize )
            { 
                printf("\nFailed reading %u bytes of dpds chunk from wave file %s\n", cdpds.cksize, argv[1] );
                return 1;
            }

            auto table = reinterpret_cast<const uint32_t*>( chunk.get() );
            for( size_t k = 0; k < (cdpds.cksize / 4); ++k )
            {
                if ( ( k % 6 ) == 0 )
                    printf( "\n\t");
                printf( "%u ", table[ k ] );
            }
        }

        printf("\n");

        if ( mmioAscend( h.Get(), &cdpds, 0 ) != MMSYSERR_NOERROR )
        {
            printf("Failed to exit 'dpds' chunk in wave file %s\n", argv[1] );
            return 1;
        }
    }

    // find optional 'seek' chunk
    if ( mmioSeek( h.Get(), riff.dwDataOffset + 4, SEEK_SET ) == -1 )
    {
        printf("Failed to reset seek\n" );
        return 1;
    }

    MMCKINFO cseek;
    memset( &cseek, 0, sizeof(cseek) );

    cseek.ckid = mmioFOURCC( 's', 'e', 'e', 'k' );
    if ( mmioDescend( h.Get(), &cseek, &riff, MMIO_FINDCHUNK ) == MMSYSERR_NOERROR )
    {
        printf("chunk 'seek', %u bytes", cseek.cksize);

        if ( cseek.cksize > 0 )
        {
            chunk.reset( new (std::nothrow) BYTE[cseek.cksize] );
            if ( !chunk )
            {
                printf("\nOut of memory loading %u bytes", cseek.cksize);
                return 1;
            }

            if ( (ULONG)mmioRead( h.Get(), (HPSTR)chunk.get(), cseek.cksize ) != cseek.cksize )
            { 
                printf("\nFailed reading %u bytes of seek chunk from wave file %s\n", cseek.cksize, argv[1] );
                return 1;
            }

            auto table = reinterpret_cast<const uint32_t*>( chunk.get() );
            for( size_t k = 0; k < (cseek.cksize / 4); ++k )
            { 
                if ( ( k % 6 ) == 0 )
                    printf( "\n\t");
                printf( "%u ", _byteswap_ulong( table[ k  ] ) ); // seek chunk entries are BigEndian
            }
        }

        printf("\n");

        if ( mmioAscend( h.Get(), &cseek, 0 ) != MMSYSERR_NOERROR )
        {
            printf("Failed to exit 'seek' chunk in wave file %s\n", argv[1] );
            return 1;
        }
    }

}