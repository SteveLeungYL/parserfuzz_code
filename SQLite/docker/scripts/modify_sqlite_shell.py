import os
import sys

fd = open("/home/sqlite/sqlite/shell.c", "r")
all_lines = fd.readlines()
all_modified_lines = "#include <sys/inotify.h>\n"

tmp_prev_line = ""
for i in range(len(all_lines)):
    cur_line = all_lines[i]
    if "data.in = stdin;" in cur_line and i+1 < len(all_lines) and "rc = process_input(&data);" in all_lines[i+1]:
        all_modified_lines += """
      // stdin is not interactive.
#define MAX_BUF_LEN 100
      int file_inotify_fd = inotify_init();
      ssize_t num_read;
      char buf[MAX_BUF_LEN];
      memset(buf, 0, MAX_BUF_LEN);

      // Use inotify to watch file modification.
      if (file_inotify_fd < 0) {
        exit(1);
      }

      char file_path[MAX_BUF_LEN];
      memset(file_path, 0, MAX_BUF_LEN);
      FILE* file_path_fd = fopen("/home/sqlite/fuzzing/fuzz_root/input_path", "r");
      fread(file_path, 1, MAX_BUF_LEN, file_path_fd);
      fclose(file_path_fd);
      //remove("/home/sqlite/fuzzing/fuzz_root/input_path");

      // Remove the appending new line symbol from the fread.
      // file_path[strlen(file_path) - 1] = '\\0';

      int wd = inotify_add_watch(file_inotify_fd, file_path, IN_MODIFY | IN_CREATE);
      if (wd == -1) {
        exit(1);
      }

      // Simply read the current file first.
      int is_skip_loop = 0;
      fseek(stdin, 0, SEEK_SET);
      int size_t = fread(buf, sizeof(buf), 5, stdin);
      buf[5] = '\\0';
      if (strcmp(buf, ".quit") == 0) {
        is_skip_loop = 0;
      } else {
        fseek(stdin, 0, SEEK_SET);
        data.in = stdin;
        rc = process_input(&data);
        fflush(stdout);
      } 

      if (seenInterrupt) {
        is_skip_loop = 1;
      }


      while (!is_skip_loop) {
         
        if (seenInterrupt) {
          break;
        }

        // Monitor the file changes.
        num_read = read(file_inotify_fd, buf, MAX_BUF_LEN);
        if (num_read <= 0) {
          /*printf("num_read is smaller than 0\\n\\n\\n");*/
          continue;
        } else {
          /*printf("Successfully notify file changes..\\n\\n\\n");*/
        }

//        fd_set rfds;
//        struct timeval tv;
//        int retval;
//   
//        /* Watch stdin (fd 0) to see when it has input. */
//        FD_ZERO(&rfds);
//        FD_SET(file_fd, &rfds);
//   
//        /* Wait up to five seconds. */
//        tv.tv_sec = 0;
//        tv.tv_usec = 2000000; // 2000 microsecond.
//
//        retval = select(file_fd+1, &rfds, NULL, NULL, &tv);
//
//        if (retval == -1) {
//          /*printf("select error \\n\\n\\n");*/
//          continue;
//        }
//        else if (retval == 0) {
//          /*printf("select timtout \\n\\n\\n");*/
//          continue;
//        }

        fseek(stdin, 0, SEEK_SET);
        memset(buf, 0, MAX_BUF_LEN);
        int size_t = fread(buf, sizeof(buf), 5, stdin);
        buf[5] = '\\0';
        
        if (strcmp(buf, ".quit") == 0) {
          break;
        } else {
          /*printf("read buf: %s\\n\\n\\n", buf);*/
        }
        fseek(stdin, 0, SEEK_SET);
        data.in = stdin;
        rc = process_input(&data);
        fflush(stdout);
      }
#undef MAX_BUF_LEN
"""

    all_modified_lines += cur_line

fd.close()
fd = open("/home/sqlite/sqlite/shell.c", "wt")
fd.write(all_modified_lines)
fd.close()
