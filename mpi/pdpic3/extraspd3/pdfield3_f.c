/* C Library for Skeleton 3D Darwin MPI PIC Code field diagnostics */
/* Wrappers for calling the Fortran routines from a C main program */

#include <complex.h>

void ppotp32_(float complex *q, float complex *pot, float complex *ffc,
              float *we, int *nx, int *ny, int *nz, int *kstrt,
              int *nvpy, int *nvpz, int *nzv, int *kxyp, int *kyzp,
              int *nzhd);

void ppdivf32_(float complex *f, float complex *df, int *nx, int *ny,
               int *nz, int *kstrt, int *nvpy, int *nvpz, int *nzv,
               int *kxyp, int *kyzp);

void ppgradf32_(float complex *df, float complex *f, int *nx, int *ny,
                int *nz, int *kstrt, int *nvpy, int *nvpz, int *nzv,
                int *kxyp, int *kyzp);

void ppcurlf32_(float complex *f, float complex *g, int *nx, int *ny,
                int *nz, int *kstrt, int *nvpy, int *nvpz, int *nzv,
                int *kxyp, int *kyzp);

void ppapotp32_(float complex *cu, float complex *axyz,
                float complex *ffc, float *ci, float *wm, int *nx,
                int *ny, int *nz, int *kstrt, int *nvpy, int *nvpz,
                int *nzv, int *kxyp, int *kyzp, int *nzhd);

void ppetfield332_(float complex *dcu, float complex *exyz,
                   float complex *ffe, float *affp, float *ci,
                   float *wf, int *nx, int *ny, int *nz, int *kstrt,
                   int *nvpy, int *nvpz, int *nzv, int *kxyp, int *kyzp,
                   int *nzhd);

void ppsmooth32_(float complex *q, float complex *qs,
                 float complex *ffc, int *nx, int *ny, int *nz,
                 int *kstrt, int *nvpy, int *nvpz, int *nzv, int *kxyp, 
                 int *kyzp, int *nzhd);

void ppsmooth332_(float complex *cu, float complex *cus,
                  float complex *ffc, int *nx, int *ny, int *nz,
                  int *kstrt, int *nvpy, int *nvpz, int *nzv, int *kxyp,
                  int *kyzp, int *nzhd);

void pprdmodes32_(float complex *pot, float complex *pott, int *nx,
                  int *ny, int *nz, int *modesx, int *modesy, 
                  int *modesz, int *kstrt, int *nvpy, int *nvpz,
                  int *nzv, int *kxyp, int *kyzp, int *modesxpd,
                  int *modesypd, int *modeszd);

void ppwrmodes32_(float complex *pot, float complex *pott, int *nx,
                  int *ny, int *nz, int *modesx, int *modesy,
                  int *modesz, int *kstrt, int *nvpy, int *nvpz,
                  int *nzv, int *kxyp, int *kyzp, int *modesxpd,
                  int *modesypd, int *modeszd);

void pprdvmodes32_(float complex *vpot, float complex *vpott, int *nx,
                   int *ny, int *nz, int *modesx, int *modesy,
                   int *modesz, int *ndim, int *kstrt, int *nvpy,
                   int *nvpz, int *nzv, int *kxyp, int *kyzp,
                   int *modesxpd, int *modesypd, int *modeszd);

void ppwrvmodes32_(float complex *vpot, float complex *vpott, int *nx,
                   int *ny, int *nz, int *modesx, int *modesy,
                   int *modesz, int *ndim, int *kstrt, int *nvpy,
                   int *nvpz, int *nzv, int *kxyp, int *kyzp,
                   int *modesxpd, int *modesypd, int *modeszd);

/* Interfaces to C */

/*--------------------------------------------------------------------*/
void cppotp32(float complex q[], float complex pot[],
              float complex ffc[], float *we, int nx, int ny, int nz,
              int kstrt, int nvpy, int nvpz, int nzv, int kxyp,
              int kyzp, int nzhd) {
   ppotp32_(q,pot,ffc,we,&nx,&ny,&nz,&kstrt,&nvpy,&nvpz,&nzv,&kxyp,
            &kyzp,&nzhd);
   return;
}

/*--------------------------------------------------------------------*/
void cppdivf32(float complex f[], float complex df[], int nx, int ny,
               int nz, int kstrt, int nvpy, int nvpz, int nzv, int kxyp,
               int kyzp) {
   ppdivf32_(f,df,&nx,&ny,&nz,&kstrt,&nvpy,&nvpz,&nzv,&kxyp,&kyzp);
   return;
}

/*--------------------------------------------------------------------*/
void cppgradf32(float complex df[], float complex f[], int nx, int ny,
                int nz, int kstrt, int nvpy, int nvpz, int nzv,
                int kxyp, int kyzp) {
   ppgradf32_(df,f,&nx,&ny,&nz,&kstrt,&nvpy,&nvpz,&nzv,&kxyp,&kyzp);
   return;
}

/*--------------------------------------------------------------------*/
void cppcurlf32(float complex f[], float complex g[], int nx, int ny,
                int nz, int kstrt, int nvpy, int nvpz, int nzv,
                int kxyp, int kyzp) {
   ppcurlf32_(f,g,&nx,&ny,&nz,&kstrt,&nvpy,&nvpz,&nzv,&kxyp,&kyzp);
   return;
}

/*--------------------------------------------------------------------*/
void cppapotp32(float complex cu[], float complex axyz[],
                float complex ffc[], float ci, float *wm, int nx,
                int ny, int nz, int kstrt, int nvpy, int nvpz, int nzv,
                int kxyp, int kyzp, int nzhd) {
   ppapotp32_(cu,axyz,ffc,&ci,wm,&nx,&ny,&nz,&kstrt,&nvpy,&nvpz,&nzv,
              &kxyp,&kyzp,&nzhd);
   return;
}

/*--------------------------------------------------------------------*/
void cppetfield332(float complex dcu[], float complex exyz[],
                   float complex ffe[], float affp, float ci, float *wf,
                   int nx, int ny, int nz, int kstrt, int nvpy,
                   int nvpz, int nzv, int kxyp, int kyzp, int nzhd) {
   ppetfield332_(dcu,exyz,ffe,&affp,&ci,wf,&nx,&ny,&nz,&kstrt,&nvpy,
                 &nvpz,&nzv,&kxyp,&kyzp,&nzhd);
   return;
}

/*--------------------------------------------------------------------*/
void cppsmooth32(float complex q[], float complex qs[],
                 float complex ffc[], int nx, int ny, int nz, int kstrt,
                 int nvpy, int nvpz, int nzv, int kxyp, int kyzp,
                 int nzhd) {
   ppsmooth32_(q,qs,ffc,&nx,&ny,&nz,&kstrt,&nvpy,&nvpz,&nzv,&kxyp,&kyzp,
               &nzhd);
   return;
}

/*--------------------------------------------------------------------*/
void cppsmooth332(float complex cu[], float complex cus[],
                  float complex ffc[], int nx, int ny, int nz,
                  int kstrt, int nvpy, int nvpz, int nzv, int kxyp,
                  int kyzp, int nzhd) {
   ppsmooth332_(cu,cus,ffc,&nx,&ny,&nz,&kstrt,&nvpy,&nvpz,&nzv,&kxyp,
                &kyzp,&nzhd);
   return;
}

/*--------------------------------------------------------------------*/
void cpprdmodes32(float complex pot[], float complex pott[], int nx,
                  int ny, int nz, int modesx, int modesy, int modesz,    
                  int kstrt, int nvpy, int nvpz, int nzv, int kxyp,
                  int kyzp, int modesxpd, int modesypd, int modeszd) {
   pprdmodes32_(pot,pott,&nx,&ny,&nz,&modesx,&modesy,&modesz,&kstrt,
                &nvpy,&nvpz,&nzv,&kxyp,&kyzp,&modesxpd,&modesypd,
                &modeszd);
   return;
}

/*--------------------------------------------------------------------*/
void cppwrmodes32(float complex pot[], float complex pott[], int nx,
                  int ny, int nz, int modesx, int modesy, int modesz,
                  int kstrt, int nvpy, int nvpz, int nzv, int kxyp,
                  int kyzp, int modesxpd, int modesypd, int modeszd) {
   ppwrmodes32_(pot,pott,&nx,&ny,&nz,&modesx,&modesy,&modesz,&kstrt,
                &nvpy,&nvpz,&nzv,&kxyp,&kyzp,&modesxpd,&modesypd,
                &modeszd);
   return;
}

/*--------------------------------------------------------------------*/
void cpprdvmodes32(float complex vpot[], float complex vpott[], int nx,
                   int ny, int nz, int modesx, int modesy, int modesz, 
                   int ndim, int kstrt, int nvpy, int nvpz, int nzv,
                   int kxyp, int kyzp, int modesxpd, int modesypd, 
                   int modeszd) {
   pprdvmodes32_(vpot,vpott,&nx,&ny,&nz,&modesx,&modesy,&modesz,&ndim,
                 &kstrt,&nvpy,&nvpz,&nzv,&kxyp,&kyzp,&modesxpd,
                 &modesypd,&modeszd);
   return;
}

/*--------------------------------------------------------------------*/
void cppwrvmodes32(float complex vpot[], float complex vpott[], int nx,
                   int ny, int nz, int modesx, int modesy, int modesz, 
                   int ndim, int kstrt, int nvpy, int nvpz, int nzv,
                   int kxyp, int kyzp, int modesxpd, int modesypd,
                   int modeszd) {
   ppwrvmodes32_(vpot,vpott,&nx,&ny,&nz,&modesx,&modesy,&modesz,&ndim,
                 &kstrt,&nvpy,&nvpz,&nzv,&kxyp,&kyzp,&modesxpd,
                 &modesypd,&modeszd);
   return;
}
