#include <stdlib.h>

int facti(int x, int r)
{
  if (x == 0)
    return r;
  else
    return facti(x - 1, x * r);
}

int main()
{
  int k = 6;
  printf("%d! = %d",k,facti(k,1));
}