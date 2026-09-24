/* Fresh segmented census. Pair stream is assembled in block order: no halo or
   assumed maximum gap is used for adjacency. SPDX-License-Identifier: MIT */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include <assert.h>
typedef uint64_t U; typedef unsigned __int128 W;
static const int bases[]={2,3,5,6,7,10,11,13,14,15,17,19,21,22,23,26,29,30,31,33,34,35,37,38,39,41,42,43,46,47,51,53,55,57,58,59,61,62,65,66,67,69,70,71,73,74,77,78,79,82,83,85,86,87,89,91,93,94,95,97,101,102,103,105};
static const int sel[]={2,3,5,6,7,10,11,13,15,17,21,29};
static const int mods[]={840,840,840,840,840,840,9240,10920,840,14280,840,24360};
static U pw(U a,U n,U p){U r=1;a%=p;while(n){if(n&1)r=(W)r*a%p;a=(W)a*a%p;n>>=1;}return r;}
static int root(U a,U p,U *f,int nf){if(a%p==0)return 0;for(int k=0;k<nf;k++)if(pw(a,(p-1)/f[k],p)==1)return 0;return 1;}
static U gcd(U a,U b){while(b){U t=a%b;a=b;b=t;}return a;}
int main(int argc,char **argv){
 if(argc<5){fprintf(stderr,"usage: census limit block mode(64|15) output_prefix\n");return 2;}
 U lim=strtoull(argv[1],0,10),block=strtoull(argv[2],0,10);int mode=atoi(argv[3]);const char*out=argv[4];
 assert(lim>=10&&lim<=10000000000ULL&&block>=2&&(mode==64||mode==15));
 int S=(int)sqrt((double)lim)+1,*sp=malloc((S+1)*sizeof(int)),ns=0;unsigned char *sm=calloc(S+1,1);
 for(int i=2;i<=S;i++)if(!sm[i]){sp[ns++]=i;for(U j=(U)i*i;j<=(U)S;j+=i)sm[j]=1;}free(sm);
 U joint[64][4]={{0}},matrix[12][12][4]={{{0}}},N=0,prev=0,pmask=0,maxgap=0,excludedN=0,excludedAA[2]={0};
 uint32_t *ch[12]={0};int ix[12];
 if(mode==64)for(int j=0;j<12;j++){ch[j]=calloc((size_t)mods[j]*150*4,sizeof(uint32_t));assert(ch[j]);for(int i=0;i<64;i++)if(sel[j]==bases[i])ix[j]=i;}
 char path[1024];snprintf(path,sizeof path,"%s.exceptions.csv",out);FILE *exc=fopen(path,"w");assert(exc);fprintf(exc,"base,p,q,first,second\n");
 snprintf(path,sizeof path,"%s.tiny.csv",out);FILE *tiny=fopen(path,"w");assert(tiny);fprintf(tiny,"p,mask\n");
 double t=omp_get_wtime();U nb=(lim+block-1)/block;
 #pragma omp parallel for ordered schedule(dynamic,1)
 for(U k=0;k<nb;k++){
   U lo=k*block,hi=lo+block;if(hi>lim)hi=lim;size_t len=hi-lo;
   unsigned char *s=calloc(len,1);U *pr=malloc(len*sizeof(U)),*mk=malloc(len*sizeof(U));assert(s&&pr&&mk);size_t np=0;
   for(int i=0;i<ns;i++){U q=sp[i];if(q*q>=hi)break;U start=((lo+q-1)/q)*q;if(start<q*q)start=q*q;for(U n=start;n<hi;n+=q)s[n-lo]=1;}
   if(lo==0){s[0]=1;if(len>1)s[1]=1;}
   for(U p=lo;p<hi;p++)if(p>=7&&!s[p-lo]){
     U m=p-1,f[32];int nf=0;
     for(int j=0;j<ns;j++){U q=sp[j];if(q*q>m)break;if(m%q==0){f[nf++]=q;do{m/=q;}while(m%q==0);}}if(m>1)f[nf++]=m;
     U mask=0;if(mode==15)mask=root(15,p,f,nf);else for(int b=0;b<64;b++)mask|=(U)root(bases[b],p,f,nf)<<b;
     pr[np]=p;mk[np++]=mask;
   }
   free(s);
   #pragma omp ordered
   {
     for(size_t j=0;j<np;j++){
       U p=pr[j],mask=mk[j];if(p<1000)fprintf(tiny,"%llu,%llu\n",(unsigned long long)p,(unsigned long long)mask);
       if(prev){U g=p-prev;N++;if(g>maxgap)maxgap=g;
         for(int b=0;b<(mode==15?1:64);b++)joint[b][2*((pmask>>b)&1)+((mask>>b)&1)]++;
         if(mode==64){assert(g%2==0&&g<=300);for(int a=0;a<12;a++){
           int x=(pmask>>ix[a])&1,y=(mask>>ix[a])&1;
           ch[a][((size_t)(prev%mods[a])*150+(g/2-1))*4+2*x+y]++;
           if((gcd(prev,mods[a])!=1||gcd(p,mods[a])!=1)&&x&&y)fprintf(exc,"%d,%llu,%llu,%d,%d\n",sel[a],(unsigned long long)prev,(unsigned long long)p,x,y);
           for(int b=0;b<12;b++)matrix[a][b][2*x+((mask>>ix[b])&1)]++;
         }
         if(g%24==10||g%24==14){excludedN++;excludedAA[0]+=((pmask>>ix[0])&1)*((mask>>ix[3])&1);excludedAA[1]+=((pmask>>ix[3])&1)*((mask>>ix[0])&1);}
         }
       }prev=p;pmask=mask;
     }
   }
   free(pr);free(mk);
 }
 fclose(exc);fclose(tiny);
 snprintf(path,sizeof path,"%s.json",out);FILE*f=fopen(path,"w");assert(f);
 fprintf(f,"{\"limit\":%llu,\"lower\":7,\"block\":%llu,\"n_pairs\":%llu,\"max_gap\":%llu,\"last_prime\":%llu,\"seconds\":%.6f,\"bases\":{",(unsigned long long)lim,(unsigned long long)block,(unsigned long long)N,(unsigned long long)maxgap,(unsigned long long)prev,omp_get_wtime()-t);
 for(int b=0;b<(mode==15?1:64);b++)fprintf(f,"%s\"%d\":[%llu,%llu,%llu,%llu]",b?",":"",mode==15?15:bases[b],(unsigned long long)joint[b][0],(unsigned long long)joint[b][1],(unsigned long long)joint[b][2],(unsigned long long)joint[b][3]);
 fprintf(f,"},\"matrix\":{");if(mode==64)for(int a=0;a<12;a++)for(int b=0;b<12;b++)fprintf(f,"%s\"%d,%d\":[%llu,%llu,%llu,%llu]",a||b?",":"",sel[a],sel[b],(unsigned long long)matrix[a][b][0],(unsigned long long)matrix[a][b][1],(unsigned long long)matrix[a][b][2],(unsigned long long)matrix[a][b][3]);
 fprintf(f,"},\"mixed_law\":[%llu,%llu,%llu]}\n",(unsigned long long)excludedN,(unsigned long long)excludedAA[0],(unsigned long long)excludedAA[1]);fclose(f);
 if(mode==64)for(int a=0;a<12;a++){snprintf(path,sizeof path,"%s.channels_%d.bin",out,sel[a]);f=fopen(path,"wb");assert(f);int64_t h[]={sel[a],mods[a],150,N};assert(fwrite(h,8,4,f)==4);size_t z=(size_t)mods[a]*150*4;assert(fwrite(ch[a],4,z,f)==z);fclose(f);free(ch[a]);}
 fprintf(stderr,"DONE limit=%llu pairs=%llu seconds=%.3f\n",(unsigned long long)lim,(unsigned long long)N,omp_get_wtime()-t);free(sp);return 0;
}
