#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include <signal.h>
#include <fcntl.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/time.h>

#define EVENT_FILE "/opt/music/run/last_event.librespot"
#define FIFO "/opt/music/run/librespot.fifo"
#define CHECK_TIME_MS 100
#define AUDIO_TIME_MS 10
#define APLAY_RESTART_MS 1000

#define STOPPED 1
#define PLAYING 2

#define MAX_BUF_LEN 16384

static int stop = 0;
static int aplay_started = 0;
static pid_t aplay_pid = -1;
static long long last_start_time = -1;
static FILE *fifo_out = NULL;

void signal_handler(int sig)
{
   fprintf(stderr, "Stopping player\n");
   if (fifo_out != NULL) {
      fclose(fifo_out);
      fifo_out = NULL;
   }
   stop = 1;
}

void msleep(int ms)
{
   int micro_secs = ms * 1000;
   usleep(micro_secs);
}

long long mtime()
{
   struct timeval tm;
   gettimeofday(&tm, NULL);
   long long t = (tm.tv_sec * 1000) + (tm.tv_usec / 1000);
   return t;
}

int check_play_status(int *prev)
{
   FILE *fin = fopen(EVENT_FILE, "r");
   static int last_value = STOPPED;
   static int err = 0;

   *prev = last_value;

   if (fin) {
      char line[1024];
      static char prev_line[1024];
      static int prev_line_init = 1;
      int  running;

      if (prev_line_init) {
         memset(prev_line, 0, 1024);
	 prev_line_init = 0;
      }

      err = 0;

      memset(line, 0, 1024);

      fgets(line, 100, fin);
      fclose(fin);

      if (strcmp(prev_line, line) != 0) {
         fprintf(stderr, "Read %s from %s\n", line, EVENT_FILE);
	 strcpy(prev_line, line);
      }

      running = strncasecmp(line, "play", strlen("play"));
      if (running == 0) { last_value = PLAYING; }
      else { last_value = STOPPED; }
   } else {
      if (!err) {
         fprintf(stderr, "Error reading %s\n", EVENT_FILE);
         err = 1;
      }
   }

   return last_value;
}

void play(char *buf, int buf_len)
{
   if (!aplay_started) {
      long long t = mtime();
      if (t > (last_start_time + APLAY_RESTART_MS)) {
	last_start_time = t;
        aplay_started = 1;
        fprintf(stderr, "Starting playing\n");
      
        aplay_pid = fork();
        if (aplay_pid == 0) {
           // in the child process
           int started = execlp("aplay", "aplay", "-f", "cd", FIFO, NULL);
	   if (started == -1) {
              fprintf(stderr, "Error starting aplay (%d, %s)\n", errno, strerror(errno));
	      exit(0);
	   }
        }
     }
   } else {
      int status;
      pid_t result = waitpid(aplay_pid, &status, WNOHANG);
      if (result == 0) {
	if (fifo_out == NULL) {
           fifo_out = fopen(FIFO, "wb");
	}
        if (fifo_out != NULL) {
           fwrite(buf, buf_len, 1, fifo_out);
        }
      } else {
        fprintf(stderr, "waitpid = %d, aplay stopped playing and exited\n", result);
        aplay_started = 0;
	if (fifo_out != NULL) {
          fclose(fifo_out);
	  fifo_out = NULL;
	}
      }
   }
}

int main()
{
   char buf[MAX_BUF_LEN];
   int  fh;
   int prev;

   fh = fileno(stdin);
   fcntl(fh, F_SETFL, fcntl(fh, F_GETFL) | O_NONBLOCK);

   signal(SIGINT, signal_handler);
   signal(SIGHUP, signal_handler);
   signal(SIGTERM, signal_handler);

   fprintf(stderr, "Starting player\n");

   while(!stop) {
     int status = check_play_status(&prev);
     ssize_t bytes = read(fh, buf, MAX_BUF_LEN);
     if (bytes > 0) {
       if (status == PLAYING) {
          if (status != prev) { fprintf(stderr, "Spotify connect wants to play\n"); } 
          play(buf, bytes);
       } 
     } else {
	msleep(AUDIO_TIME_MS);
     }

     if (status != PLAYING) {
       if (aplay_started && aplay_pid > 0) {
          kill(aplay_pid, SIGTERM);
	  play(buf, bytes);
	  aplay_pid = -1;
       }

       if (status != prev) { fprintf(stderr, "Spotify connect wants something else\n"); } 
       msleep(CHECK_TIME_MS);
     }
   }

   fprintf(stderr, "Exiting player\n");

   return 0;
}

