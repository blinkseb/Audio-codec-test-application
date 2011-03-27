#include <iostream>
#include <cstring>
#include <cstdlib>
#include <string>
#include <sstream>
#include <dlfcn.h>
#include <stdint.h>
#include <cstdio>

#include <sndfile.h>
#include <sndfile.hh>

#include "xbmc_ac_types.h"

using namespace std;

void syntax()
{
  cerr << "Audio codec add-on test program" << endl
       << "   syntax: wavwriter <library> <file> [options]" << endl
       << "  options: -o file.wav     - output to file.wav." << endl
       << "                             default is output to output.wav" << endl
       << "           -t i            - play track i" << endl
       << "                           - default is track 1" << endl
       << "           -ss mmss[:nntt] - start from position mmss, end at nntt" << endl
       << "                             default is to play the entire track" << endl;
}

typedef void (*get_addont)(struct AudioCodec* pAC);

int64_t parse_time_string(const string& time)
{
  stringstream str;
  str << time.substr(0,2);
  int64_t mins;
  str >> mins;
  str.clear();
  str << time.substr(2,2);
  int64_t secs;
  str >> secs;

  return mins*60*1000+secs*1000;
}

int main(int argc, char** argv)
{
  if (argc < 3)
  {
    syntax();
    return 1;
  }
  string lib   = argv[1];
  string file  = argv[2];
  int64_t start = 0;
  int64_t end   = -1;
  string outputfile="output.wav";
  int track = 1;
  for (int i=3;i<argc;++i)
  {
    if (strcmp(argv[i],"-o") == 0 && i+1 < argc)
      outputfile = argv[i+1];
    if (strcmp(argv[i],"-t") == 0 && i+1 < argc)
      track = atoi(argv[i+1]);
    if (strcmp(argv[i],"-ss") == 0 && i+1 < argc)
    {
      const char* col = strchr(argv[i+1],':');
      start = parse_time_string(argv[i+1]);
      if (col)
        end = parse_time_string(col+1);
    }
  }
  void* dll = dlopen(lib.c_str(),RTLD_NOW);
  get_addont get_addon = (get_addont)dlsym(dll,"get_addon");
  AudioCodec codec;
  get_addon(&codec);
  
  if (!codec.Init || !codec.DeInit || !codec.ReadPCM || !codec.Seek)
  {
    cerr << "Failed to load audio codec library." << endl;
    return 2;
  }

  AC_INFO* info = codec.Init(file.c_str(),track);
  if (!info)
  {
    cerr << "Failed to load audio file." << endl;
    return 3;
  }
  if (end == -1)
    end = info->totaltime;

  cerr << "Outputting track " << track << " from " << file 
       << " to " << (outputfile.empty()?"stdout":outputfile) << " using " 
       << lib << endl
       << "Outputting from position " << start/1000 << " to position " 
       << end/1000 << endl;

  char buffer[8192];
  int64_t data = (end-start)/1000*info->channels
                                 *info->samplerate*info->bitrate/8;

  int format = SF_FORMAT_WAV;
  if (info->bitrate == 8)
    format |= SF_FORMAT_PCM_S8;
  if (info->bitrate == 16)
    format |= SF_FORMAT_PCM_16;
  if (info->bitrate/8 == 3)
    format |= SF_FORMAT_PCM_24;
  SndfileHandle output(outputfile.c_str(),SFM_WRITE,
                       format,info->channels,info->samplerate);

  codec.Seek(info,start);
  unsigned int size;
  while (data > 0 && 
         codec.ReadPCM(info,buffer,data<8192?data:8192,&size) == READ_SUCCESS)
  {
    if (size == 0)
      break;
    output.write((const short int*)buffer,size/(info->bitrate/8));
    data -= size;
  }
  codec.DeInit(info);

  dlclose(dll);

  return 0;
}
