#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *safe_alloc_getsN(int n) {
  char *str = calloc(n + 1, sizeof(char));

  if (!fgets(str, n + 1, stdin)) {
    free(str);
    return NULL;
  }

  int len = strlen(str);
  if (str[len-1] == '\n') str[len-1] = 0;
  else {
    int c;
    while ((c = getchar()) != '\n' && c != EOF);
  }
  return str;
}

int prompt_for_number(unsigned short *out) {
  char *str = (char *)safe_alloc_getsN(5);
  if (!str) return 1;
  if (strlen(str) == 0) {
    free(str);
    return 1;
  }
  *out = atoi(str);
  free(str);
  return 0;
}

const unsigned short notes[] = {440,466,494,523,262,277,294,311,330,349,349,370,392,415};

int prompt_for_freq(unsigned short *out) {
  char *str = safe_alloc_getsN(3);
  if (!str) return 1;
  int len = strlen(str);

  int idx = 0;
  int shift = 0;

  if (len < 2) {
    free(str);
    return 1;
  }

  if (strncmp(str, "res", 3) == 0) {
    *out = 0;
    free(str);
    return 0;
  }

  if (len >= 2) {
    char note = str[0];
    if (note >= 'A' && note <= 'Z') note -= 'A' - 'a';
    if (note < 'a' || note > 'g') {
      free(str);
      return 2;
    }
    idx = (note - 'a') * 2;

    char octave = str[1];
    if (octave < '0' || octave > '9') {
      free(str);
      return 2;
    }
    shift = octave - '0';


    if (len == 3) {
      char sign = str[2];
      if (sign == '#') idx++;
      else if (sign == 'b') idx--;
      else {
        free(str);
        return 2;
      }
    }

    *out = notes[idx];
    if (shift > 4) {
      *out = *out << (shift - 4);
    } else if (shift < 4) {
      *out = *out >> (shift - 4);
    }
  }

  free(str);
  return 0;
}

int main(int argc, const char **argv) {
  if (argc != 3) {
     printf("Invalid arguments\n");
    return 1;
  }
  char *file = (char *)argv[1];
  FILE *fp = fopen(file, "wb");
  char *title = (char *)argv[2];
  unsigned short len = (unsigned short)strlen(title);

  fwrite((const void *)(&len), sizeof(unsigned short), 1, fp);
  fwrite((const void *)title, sizeof(char), len, fp);

  while (1) {
    unsigned short freq = 0;
    unsigned short duration = 0;
    printf("note: ");
    if (prompt_for_freq(&freq) != 0) break;
    printf("duration: ");
    if (prompt_for_number(&duration) != 0) break;
    printf("lyric: ");
    char *lyric = safe_alloc_getsN(256);
    char len = 0;
    if (lyric != 0) len = (char)strlen(lyric);
    fwrite((void *)(&freq), sizeof(unsigned short), 1, fp);
    fwrite((const void *)(&duration), sizeof(unsigned short), 1, fp);
    fwrite((const void *)(&len), sizeof(char), 1, fp);
    fwrite((const void *)lyric, sizeof(char), strlen(lyric), fp);
    free((void *)lyric);
    printf("===============\n");
  }
  fclose(fp);
  return 0;
}
