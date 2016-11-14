#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>


char *safe_alloc_getsN(int n) {
  char *str = calloc(n + 1, sizeof(char));
  if (!fgets(str, n + 1 ,stdin)) {
    printf("asdf - fuck");
    free(str);
    return NULL;
  }
  int len = strlen(str);
  if (str[len-1] == '\n') str[len-1] = 0;
  return str;
}

int prompt_for_number(uint16_t *out) {
  char *str = safe_alloc_getsN(5); // 5 places max for 16-bit number
  if (!str) return 1;
  if (strlen(str) == 0) {
    printf("trapping\n");
    free(str);
    return 1;
  }
  *out = atoi(str);
  free(str);
  return 0; 
}

// Contains B# (C)
const uint16_t notes[] = {
  440, // A4
  466, // A4#
  494, // B4
  523, // B4#
  262, // C4
  277, // C4#
  294, // D4
  311, // D4#
  330, // E4
  349, // E4#
  349, // F4
  370, // F4#
  392, // G4
  415 // G4#
};

// converts things like C6# or E4b to a frequency
int prompt_for_freq(uint16_t *out) {
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
    if (note >= 'A' && note <= 'Z') note = note - 'A' + 'a';
    if (note < 'a' || note > 'g') {
      free(str);
      return 2;
    }
    idx = (note - 'a') * 2;

    char octave = str[1]; 
    if (!(octave >= '0' && octave <= '9')) {
      free(str);
      return 2;
    }
    shift = octave - '0';
  } 

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

  free(str);
  return 0;
}

int main(int argc, char **argv) {
  FILE *fp =  fopen(argv[1], "wb");
  const char *title = argv[2];
  uint16_t len = (uint16_t)strlen(title);

  fwrite(&len, sizeof(uint16_t), 1, fp); // write the title len
  fwrite(title, sizeof(char), len, fp); // write the title

  while (1) {
    int16_t freq = 0;
    int16_t duration = 0;
    printf("note: ");
    if (prompt_for_freq(&freq) != 0) break;
    printf("duration: ");
    if (prompt_for_number(&duration) != 0) break;
    printf("lyric: ");
    char *lyric = safe_alloc_getsN(256);
    char len = lyric ? (char)strlen(lyric) : 0;
    fwrite(&freq, sizeof(uint16_t), 1, fp);
    fwrite(&duration, sizeof(uint16_t), 1, fp);
    fwrite(&len, sizeof(char), 1, fp);
    fwrite(lyric, sizeof(char), strlen(lyric), fp);
    free(lyric);
    printf("===============\n");
  }

  fclose(fp);
  return 0;
}

