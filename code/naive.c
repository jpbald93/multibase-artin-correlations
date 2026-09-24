/* Literal multiplicative-order enumeration, not p-1 factor tests. MIT. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <omp.h>
static int root(uint64_t a,uint64_t p){if(a%p==0)return 0;uint64_t x=1;for(uint64_t k=1;k<p;k++){x=x*a%p;if(x==1)return k==p-1;}abort();}
int main(int argc,char**argv){int B=argc>1?atoi(argv[1]):1000000;char*s=calloc(B,1);int*pr=malloc(B*sizeof(int)),n=0;for(int p=2;p<B;p++)if(!s[p]){if(p>=7)pr[n++]=p;for(int64_t j=(int64_t)p*p;j<B;j+=p)s[j]=1;}free(s);unsigned char *a=malloc(n),*b=malloc(n);double t=omp_get_wtime();
#pragma omp parallel for schedule(dynamic,64)
for(int i=0;i<n;i++){a[i]=root(2,pr[i]);b[i]=root(6,pr[i]);}
long eligible=0,v26=0,v62=0;for(int i=0;i<n-1;i++){int g=(pr[i+1]-pr[i])%24;if(g==10||g==14){eligible++;v26+=a[i]*b[i+1];v62+=b[i]*a[i+1];}}
printf("{\"bound\":%d,\"lower\":7,\"pairs\":%d,\"eligible\":%ld,\"violations26\":%ld,\"violations62\":%ld,\"seconds\":%.6f}\n",B,n-1,eligible,v26,v62,omp_get_wtime()-t);free(pr);free(a);free(b);}
