c Fortran Library for Skeleton 3D Electrostatic MPI PIC Code
c written by Viktor K. Decyk, UCLA
c-----------------------------------------------------------------------
      subroutine PDICOMP32L(edges,nyzp,noff,nypmx,nzpmx,nypmn,nzpmn,ny, 
     1nz,kstrt,nvpy,nvpz,idps,idds)
c this subroutine determines spatial boundaries for uniform particle
c decomposition, calculates number of grid points in each spatial
c region, and the offset of these grid points from the global address
c nvpy must be < ny and nvpz must be < nz.
c some combinations of ny and nvpy and nz and nvpz result in a zero
c value of nyzp.  this is not supported.
c input: ny, nz, kstrt, nvpy, nvpz, idps, idds
c output: edges, nyzp, noff, nypmx, nzpmx, nypmn, nzpmn
c for 2D spatial decomposition
c edges(1:2) = lower/upper boundary in y of particle partition
c edges(3:4) = back/front boundary in z of particle partition
c nyzp(1:2) = number of primary (complete) gridpoints in y/z
c noff(1) = lowermost global gridpoint in y in particle partition
c noff(2) = backmost global gridpoint in z in particle partition
c nypmx = maximum size of particle partition in y, including guard cells
c nzpmx = maximum size of particle partition in z, including guard cells
c nypmn = minimum value of nyzp(1)
c nzpmn = minimum value of nyzp(2)
c ny/nz = system length in y/z direction
c kstrt = starting data block number (processor id + 1)
c nvpy/nvpz = number of real or virtual processors in y/z
c idps = number of particle partition boundaries = 4
c idds = dimensionality of domain decomposition = 2
      implicit none
      integer nypmx, nzpmx, nypmn, nzpmn, ny, nz, kstrt, nvpy, nvpz
      integer idps, idds
      integer nyzp, noff
      real edges
      dimension nyzp(idds), noff(idds)
      dimension edges(idps)
c local data
      integer jb, kb, kyp, kzp
      real at1, at2, any, anz
      integer myzpm, iwork4
      dimension myzpm(4), iwork4(4)
      any = real(ny)
      anz = real(nz)
c determine decomposition
c find processor id in y/z
      kb = (kstrt - 1)/nvpy
      jb = kstrt - nvpy*kb - 1
c boundaries in y
      kyp = (ny - 1)/nvpy + 1
      at1 = real(kyp)
      edges(1) = at1*real(jb)
      if (edges(1).gt.any) edges(1) = any
      noff(1) = edges(1)
      edges(2) = at1*real(jb + 1)
      if (edges(2).gt.any) edges(2) = any
      jb = edges(2)
      nyzp(1) = jb - noff(1)
c boundaries in z
      kzp = (nz - 1)/nvpz + 1
      at2 = real(kzp)
      edges(3) = at2*real(kb)
      if (edges(3).gt.anz) edges(3) = anz
      noff(2) = edges(3)
      edges(4) = at2*real(kb + 1)
      if (edges(4).gt.anz) edges(4) = anz
      kb = edges(4)
      nyzp(2) = kb - noff(2)
c find maximum/minimum partition size in y and z
      myzpm(1) = nyzp(1)
      myzpm(2) = -nyzp(1)
      myzpm(3) = nyzp(2)
      myzpm(4) = -nyzp(2)
      call PPIMAX(myzpm,iwork4,4)
      nypmx = myzpm(1) + 1
      nypmn = -myzpm(2)
      nzpmx = myzpm(3) + 1
      nzpmn = -myzpm(4)
      return
      end
c-----------------------------------------------------------------------
      subroutine FCOMP32(nvp,nx,ny,nz,nvpy,nvpz,ierr)
c determines optimal partition for nvp processors
c input: nvp, number of processors, nx, ny, nz = number of grids
c output: nvpy, nvpz, processors in y, z direction, ierr = error code
c nvp = number of real or virtual processors obtained
c nx/ny/nz = system length in x/y/z direction
c nvpy/nvpz = number of real or virtual processors in y/z
c ierr = (0,1) = (no,yes) error condition exists
      implicit none
      integer nvp, nx, ny, nz, nvpy, nvpz, ierr
c local data
      integer nxh, lvp
      double precision dt1
      nxh = nx/2
      ierr = 0
c algorithm 1: prefer equal number of grids in y and z partitions
      dt1 = sqrt(dble(nvp)*dble(ny)/dble(nz))
c algorithm 2: prefer equal number of grids in x*y and y*z partitions
c     dt1 = sqrt(nvp*sqrt(dble(nxh)/dble(nz)))
c return total number of processors in y and z
      nvpy = real(dt1)
      if (nvpy.lt.1) nvpy = 1
      nvpz = nvp/nvpy
      lvp = nvpy*nvpz
      if (lvp.gt.nvp) then
         write (*,*) 'invalid partition:nvpy,nvpz,nvp=', nvpy, nvpz, nvp
         ierr = 1
         return
      endif
   10 if (lvp.ne.nvp) then
         nvpy = nvpy - 1
         nvpz = nvp/nvpy
         lvp = nvpy*nvpz
         go to 10
      endif
      nvp = lvp
      return
      end
c-----------------------------------------------------------------------
      subroutine PDISTR32(part,edges,npp,nps,vtx,vty,vtz,vdx,vdy,vdz,npx
     1,npy,npz,nx,ny,nz,idimp,npmax,idps,ipbc,ierr)
c for 3d code, this subroutine calculates initial particle co-ordinates
c and velocities with uniform density and maxwellian velocity with drift
c for distributed data with 2D spatial decomposition
c part(1,n) = position x of particle n in partition
c part(2,n) = position y of particle n in partition
c part(3,n) = position z of particle n in partition
c part(4,n) = velocity vx of particle n in partition
c part(5,n) = velocity vy of particle n in partition
c part(6,n) = velocity vz of particle n in partition
c edges(1) = lower boundary in y of particle partition
c edges(2) = upper boundary in y of particle partition
c edges(3) = back boundary in z of particle partition
c edges(4) = front boundary in z of particle partition
c npp = number of particles in partition
c nps = starting address of particles in partition
c vtx/vty/vtz = thermal velocity of electrons in x/y/z direction
c vdx/vdy/vdz = drift velocity of beam electrons in x/y/z direction
c npx/npy/npz = initial number of particles distributed in x/y/z
c direction
c nx/ny/nz = system length in x/y/z direction
c idimp = size of phase space = 6
c npmax = maximum number of particles in each partition
c idps = number of partition boundaries
c ipbc = particle boundary condition = (0,1,2,3) =
c (none,3d periodic,3d reflecting,mixed 2d reflecting/1d periodic)
c ierr = (0,1) = (no,yes) error condition exists
c ranorm = gaussian random number with zero mean and unit variance
c with 2D spatial decomposition
      implicit none
      integer npp, nps, npx, npy, npz, nx, ny, nz, idimp, npmax, idps
      integer ipbc, ierr
      real vtx, vty, vtz, vdx, vdy, vdz
      real part, edges
      dimension part(idimp,npmax), edges(idps)
c local data
      integer j, k, l, npt, npxyzp
      real edgelx, edgely, edgelz, at1, at2, at3
      real xt, yt, zt, vxt, vyt, vzt
      double precision dnpxy, dnpxyz, dt1
      integer ierr1, iwork1
      double precision sum4, work4
      dimension ierr1(1), iwork1(1), sum4(4), work4(4)
      double precision ranorm
      ierr = 0
c particle distribution constant
      dnpxy = dble(npx)*dble(npy)
c set boundary values
      edgelx = 0.0
      edgely = 0.0
      edgelz = 0.0
      at1 = real(nx)/real(npx)
      at2 = real(ny)/real(npy)
      at3 = real(nz)/real(npz)
      if (ipbc.eq.2) then
         edgelx = 1.0
         edgely = 1.0
         edgelz = 1.0
         at1 = real(nx-2)/real(npx)
         at2 = real(ny-2)/real(npy)
         at3 = real(nz-2)/real(npz)
      else if (ipbc.eq.3) then
         edgelx = 1.0
         edgely = 1.0
         edgelz = 0.0
         at1 = real(nx-2)/real(npx)
         at2 = real(ny-2)/real(npy)
         at3 = real(nz)/real(npz)
      endif
      do 30 l = 1, npz
      zt = edgelz + at3*(real(l) - 0.5)
      do 20 k = 1, npy
      yt = edgely + at2*(real(k) - 0.5)
      do 10 j = 1, npx
c uniform density profile
      xt = edgelx + at1*(real(j) - 0.5)
c maxwellian velocity distribution
      vxt = vtx*ranorm()
      vyt = vty*ranorm()
      vzt = vtz*ranorm()
      if ((yt.ge.edges(1)).and.(yt.lt.edges(2))) then
         if ((zt.ge.edges(3)).and.(zt.lt.edges(4))) then
            npt = npp + 1
            if (npt.le.npmax) then
               part(1,npt) = xt
               part(2,npt) = yt
               part(3,npt) = zt
               part(4,npt) = vxt
               part(5,npt) = vyt
               part(6,npt) = vzt
               npp = npt
            else
               ierr = ierr + 1
            endif
         endif
      endif
   10 continue
   20 continue
   30 continue
      npxyzp = 0
c add correct drift
      sum4(1) = 0.0d0
      sum4(2) = 0.0d0
      sum4(3) = 0.0d0
      do 40 j = nps, npp
      npxyzp = npxyzp + 1
      sum4(1) = sum4(1) + part(4,j)
      sum4(2) = sum4(2) + part(5,j)
      sum4(3) = sum4(3) + part(6,j)
   40 continue
      sum4(4) = npxyzp
      call PPDSUM(sum4,work4,4)
      dnpxyz = sum4(4)
      ierr1(1) = ierr
      call PPIMAX(ierr,iwork1,1)
      ierr = ierr1(1)
      dt1 = 1.0d0/dnpxyz
      sum4(1) = dt1*sum4(1) - vdx
      sum4(2) = dt1*sum4(2) - vdy
      sum4(3) = dt1*sum4(3) - vdz
      do 50 j = nps, npp
      part(4,j) = part(4,j) - sum4(1)
      part(5,j) = part(5,j) - sum4(2)
      part(6,j) = part(6,j) - sum4(3)
   50 continue
c process errors
      dnpxyz = dnpxyz - dnpxy*dble(npz)
      if (dnpxyz.ne.0.0d0) ierr = dnpxyz
      return
      end
c-----------------------------------------------------------------------
      subroutine PPGPUSH32L(part,fxyz,edges,npp,noff,ihole,qbm,dt,ek,nx,
     1ny,nz,idimp,npmax,nxv,nypmx,nzpmx,idps,idds,ntmax,ipbc)
c for 3d code, this subroutine updates particle co-ordinates and
c velocities using leap-frog scheme in time and first-order linear
c interpolation in space, with various boundary conditions.
c also determines list of particles which are leaving this processor
c for distributed data, with 2D spatial decomposition
c scalar version using guard cells
c 90 flops/particle, 30 loads, 6 stores
c input: all except ihole, output: part, ihole, ek
c equations used are:
c vx(t+dt/2) = vx(t-dt/2) + (q/m)*fx(x(t),y(t),z(t))*dt,
c vy(t+dt/2) = vy(t-dt/2) + (q/m)*fy(x(t),y(t),z(t))*dt,
c vz(t+dt/2) = vz(t-dt/2) + (q/m)*fz(x(t),y(t),z(t))*dt,
c where q/m is charge/mass, and
c x(t+dt) = x(t) + vx(t+dt/2)*dt, y(t+dt) = y(t) + vy(t+dt/2)*dt,
c z(t+dt) = z(t) + vz(t+dt/2)*dt
c fx(x(t),y(t),z(t)), fy(x(t),y(t),z(t)), and fz(x(t),y(t),z(t))
c are approximated by interpolation from the nearest grid points:
c fx(x,y,z) = (1-dz)*((1-dy)*((1-dx)*fx(n,m,l)+dx*fx(n+1,m,l))
c                + dy*((1-dx)*fx(n,m+1,l) + dx*fx(n+1,m+1,l)))
c           + dz*((1-dy)*((1-dx)*fx(n,m,l+1)+dx*fx(n+1,m,l+1))
c                + dy*((1-dx)*fx(n,m+1,l+1) + dx*fx(n+1,m+1,l+1)))
c fy(x,y,z) = (1-dz)*((1-dy)*((1-dx)*fy(n,m,l)+dx*fy(n+1,m,l))
c                + dy*((1-dx)*fy(n,m+1,l) + dx*fy(n+1,m+1,l)))
c           + dz*((1-dy)*((1-dx)*fy(n,m,l+1)+dx*fy(n+1,m,l+1))
c                + dy*((1-dx)*fy(n,m+1,l+1) + dx*fy(n+1,m+1,l+1)))
c fz(x,y,z) = (1-dz)*((1-dy)*((1-dx)*fz(n,m,l)+dx*fz(n+1,m,l))
c                + dy*((1-dx)*fz(n,m+1,l) + dx*fz(n+1,m+1,l)))
c           + dz*((1-dy)*((1-dx)*fz(n,m,l+1)+dx*fz(n+1,m,l+1))
c                + dy*((1-dx)*fz(n,m+1,l+1) + dx*fz(n+1,m+1,l+1)))
c where n,m,l = leftmost grid points and dx = x-n, dy = y-m, dz = z-l
c part(1,n) = position x of particle n in partition
c part(2,n) = position y of particle n in partition
c part(3,n) = position z of particle n in partition
c part(4,n) = velocity vx of particle n in partition
c part(5,n) = velocity vy of particle n in partition
c part(6,n) = velocity vz of particle n in partition
c fxyz(1,j,k,l) = x component of force/charge at grid (j,kk,ll)
c fxyz(2,j,k,l) = y component of force/charge at grid (j,kk,ll)
c fxyz(3,j,k,l) = z component of force/charge at grid (j,kk,ll)
c in other words, fxyz are the convolutions of the electric field
c over the particle shape,
c where kk = k + noff(1) - 1, and ll = l + noff(2) - 1
c edges(1:2) = lower/upper boundary in y of particle partition
c edges(3:4) = back/front boundary in z of particle partition
c npp = number of particles in partition
c noff(1) = lowermost global gridpoint in y in particle partition
c noff(2) = backmost global gridpoint in z in particle partition
c ihole(:,2) = location of holes left in y/z in particle arrays
c ihole(1,:) = ih, number of holes left in y/z (error, if negative)
c qbm = particle charge/mass ratio
c dt = time interval between successive calculations
c kinetic energy/mass at time t is also calculated, using
c ek = .125*sum((vx(t+dt/2)+vx(t-dt/2))**2+(vy(t+dt/2)+vy(t-dt/2))**2+
c (vz(t+dt/2)+vz(t-dt/2))**2)
c nx/ny/nz = system length in x/y/z direction
c idimp = size of phase space = 6
c npmax = maximum number of particles in each partition
c nxv = first dimension of field array, must be >= nx+1
c nypmx = maximum size of particle partition in y, including guard cells
c nzpmx = maximum size of particle partition in z, including guard cells
c idps = number of particle partition boundaries = 4
c idds = dimensionality of domain decomposition
c ntmax = size of hole array for particles leaving processors
c ipbc = particle boundary condition = (0,1,2,3) =
c (none,3d periodic,3d reflecting,mixed 2d reflecting/1d periodic)
      implicit none
      integer npp, nx, ny, nz, idimp, npmax, nxv, nypmx, nzpmx, idps
      integer idds, ntmax, ipbc
      real qbm, dt, ek
      real part, fxyz, edges
      integer noff, ihole
      dimension part(idimp,npmax), fxyz(3,nxv,nypmx,nzpmx)
      dimension edges(idps)
      dimension noff(idds), ihole(ntmax+1,2)
c local data
      integer j, mnoff, lnoff, nn, mm, ll, np, mp, lp, ih1, ih2, nh
      real qtm, edgelx, edgely, edgelz, edgerx, edgery, edgerz
      real dxp, dyp, dzp, amx, amy, amz, dx1, dx, dy, dz
      double precision sum1
      qtm = qbm*dt
      sum1 = 0.0d0
c set boundary values
      edgelx = 0.0
      edgely = 0.0
      edgelz = 0.0
      edgerx = real(nx)
      edgery = real(ny)
      edgerz = real(nz)
      if (ipbc.eq.2) then
         edgelx = 1.0
         edgely = 1.0
         edgelz = 1.0
         edgerx = real(nx-1)
         edgery = real(ny-1)
         edgerz = real(nz-1)
      else if (ipbc.eq.3) then
         edgelx = 1.0
         edgely = 1.0
         edgerx = real(nx-1)
         edgery = real(ny-1)
      endif
      mnoff = noff(1) - 1
      lnoff = noff(2) - 1
      ih1 = 0
      ih2 = 0
      nh = 0
c find interpolation weights
      do 10 j = 1, npp
      nn = part(1,j)
      mm = part(2,j)
      ll = part(3,j)
      dxp = part(1,j) - real(nn)
      dyp = part(2,j) - real(mm)
      dzp = part(3,j) - real(ll)
      nn = nn + 1
      amx = 1.0 - dxp
      amy = 1.0 - dyp
      np = nn + 1
      mm = mm - mnoff
      dx1 = dxp*dyp
      dyp = amx*dyp
      mp = mm + 1
      amx = amx*amy
      amz = 1.0 - dzp
      ll = ll - lnoff
      amy = dxp*amy
      lp = ll + 1
c find acceleration
      dx = amz*(amx*fxyz(1,nn,mm,ll) + amy*fxyz(1,np,mm,ll)
     1        + dyp*fxyz(1,nn,mp,ll) + dx1*fxyz(1,np,mp,ll))
     2   + dzp*(amx*fxyz(1,nn,mm,lp) + amy*fxyz(1,np,mm,lp)
     3        + dyp*fxyz(1,nn,mp,lp) + dx1*fxyz(1,np,mp,lp))
      dy = amz*(amx*fxyz(2,nn,mm,ll) + amy*fxyz(2,np,mm,ll)
     1        + dyp*fxyz(2,nn,mp,ll) + dx1*fxyz(2,np,mp,ll))
     2   + dzp*(amx*fxyz(2,nn,mm,lp) + amy*fxyz(2,np,mm,lp)
     3        + dyp*fxyz(2,nn,mp,lp) + dx1*fxyz(2,np,mp,lp))
      dz = amz*(amx*fxyz(3,nn,mm,ll) + amy*fxyz(3,np,mm,ll)
     1        + dyp*fxyz(3,nn,mp,ll) + dx1*fxyz(3,np,mp,ll))
     2   + dzp*(amx*fxyz(3,nn,mm,lp) + amy*fxyz(3,np,mm,lp)
     3        + dyp*fxyz(3,nn,mp,lp) + dx1*fxyz(3,np,mp,lp))
c new velocity
      dx = part(4,j) + qtm*dx
      dy = part(5,j) + qtm*dy
      dz = part(6,j) + qtm*dz
c average kinetic energy
      sum1 = sum1 + (dx + part(4,j))**2 + (dy + part(5,j))**2
     1            + (dz + part(6,j))**2
      part(4,j) = dx
      part(5,j) = dy
      part(6,j) = dz
c new position
      dx = part(1,j) + dx*dt
      dy = part(2,j) + dy*dt
      dz = part(3,j) + dz*dt
c periodic boundary conditions in x
      if (ipbc.eq.1) then
         if (dx.lt.edgelx) dx = dx + edgerx
         if (dx.ge.edgerx) dx = dx - edgerx
c reflecting boundary conditions
      else if (ipbc.eq.2) then
         if ((dx.lt.edgelx).or.(dx.ge.edgerx)) then
            dx = part(1,j)
            part(4,j) = -part(4,j)
         endif
         if ((dy.lt.edgely).or.(dy.ge.edgery)) then
            dy = part(2,j)
            part(5,j) = -part(5,j)
         endif
         if ((dz.lt.edgelz).or.(dz.ge.edgerz)) then
            dz = part(3,j)
            part(6,j) = -part(6,j)
         endif
c mixed reflecting/periodic boundary conditions
      else if (ipbc.eq.3) then
         if ((dx.lt.edgelx).or.(dx.ge.edgerx)) then
            dx = part(1,j)
            part(4,j) = -part(4,j)
         endif
         if ((dy.lt.edgely).or.(dy.ge.edgery)) then
            dy = part(2,j)
            part(5,j) = -part(5,j)
         endif
      endif
c find particles out of bounds
c check particles leaving in y direction or y and z
      if ((dy.lt.edges(1)).or.(dy.ge.edges(2))) then
         ih1 = ih1 + 1
         if (ih1.le.ntmax) then
            ihole(ih1+1,1) = j
         else
            nh = 1
         endif
c check particles leaving in z direction only
      else if ((dz.lt.edges(3)).or.(dz.ge.edges(4))) then
         ih2 = ih2 + 1
         if (ih2.le.ntmax) then
            ihole(ih2+1,2) = j
         else
            nh = 1
         endif
      endif
c set new position
      part(1,j) = dx
      part(2,j) = dy
      part(3,j) = dz
   10 continue
c set end of file flag
      if (nh.gt.0) ih1 = -max(ih1,ih2)
      ihole(1,1) = ih1
      ihole(1,2) = ih2
c normalize kinetic energy
      ek = ek + 0.125*sum1
      return
      end
c-----------------------------------------------------------------------
      subroutine PPGPOST32L(part,q,npp,noff,qm,idimp,npmax,nxv,nypmx,   
     1nzpmx,idds)
c for 3d code, this subroutine calculates particle charge density
c using first-order linear interpolation, with 2D spatial decomposition
c scalar version using guard cells, for distributed data
c 33 flops/particle, 11 loads, 8 stores
c input: all, output: q
c charge density is approximated by values at the nearest grid points
c q(n,m,l)=qm*(1.-dx)*(1.-dy)*(1.-dz)
c q(n+1,m,l)=qm*dx*(1.-dy)*(1.-dz)
c q(n,m+1,l)=qm*(1.-dx)*dy*(1.-dz)
c q(n+1,m+1,l)=qm*dx*dy*(1.-dz)
c q(n,m,l+1)=qm*(1.-dx)*(1.-dy)*dz
c q(n+1,m,l+1)=qm*dx*(1.-dy)*dz
c q(n,m+1,l+1)=qm*(1.-dx)*dy*dz
c q(n+1,m+1,l+1)=qm*dx*dy*dz
c where n,m,l = leftmost grid points and dx = x-n, dy = y-m, dz = z-l
c part(1,n) = position x of particle n in partition
c part(2,n) = position y of particle n in partition
c part(3,n) = position z of particle n in partition
c q(j,k,l) = charge density at grid point (j,kk,ll),
c where kk = k + noff(1) - 1, and ll = l + noff(2) - 1
c npp = number of particles in partition
c noff(1) = lowermost global gridpoint in y in particle partition
c noff(2) = backmost global gridpoint in z in particle partition
c qm = charge on particle, in units of e
c idimp = size of phase space = 6
c npmax = maximum number of particles in each partition
c nxv = first dimension of charge array, must be >= nx+1
c nypmx = maximum size of particle partition in y, including guard cells
c nzpmx = maximum size of particle partition in z, including guard cells
c idds = dimensionality of domain decomposition
      implicit none
      integer npp, idimp, npmax, nxv, nypmx, nzpmx, idds
      real qm
      integer noff
      real part, q
      dimension part(idimp,npmax), q(nxv,nypmx,nzpmx)
      dimension noff(idds)
c local data
      integer j, mnoff, lnoff, nn, mm, ll, np, mp, lp
      real dxp, dyp, dzp, amx, amy, amz, dx1
      mnoff = noff(1) - 1
      lnoff = noff(2) - 1
c find interpolation weights
      do 10 j = 1, npp
      nn = part(1,j)
      mm = part(2,j)
      ll = part(3,j)
      dxp = qm*(part(1,j) - real(nn))
      dyp = part(2,j) - real(mm)
      dzp = part(3,j) - real(ll)
      nn = nn + 1
      amx = qm - dxp
      amy = 1.0 - dyp
      np = nn + 1
      mm = mm - mnoff
      dx1 = dxp*dyp
      dyp = amx*dyp
      mp = mm + 1
      amx = amx*amy
      amz = 1.0 - dzp
      ll = ll - lnoff
      amy = dxp*amy
      lp = ll + 1
c deposit charge
      q(nn,mm,ll) = q(nn,mm,ll) + amx*amz
      q(np,mm,ll) = q(np,mm,ll) + amy*amz
      q(nn,mp,ll) = q(nn,mp,ll) + dyp*amz
      q(np,mp,ll) = q(np,mp,ll) + dx1*amz
      q(nn,mm,lp) = q(nn,mm,lp) + amx*dzp
      q(np,mm,lp) = q(np,mm,lp) + amy*dzp
      q(nn,mp,lp) = q(nn,mp,lp) + dyp*dzp
      q(np,mp,lp) = q(np,mp,lp) + dx1*dzp
   10 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPDSORTP32YZL(parta,partb,npic,npp,noff,nyzp,idimp,    
     1npmax,nyzpm1,idds)
c this subroutine sorts particles by y,z grid
c linear interpolation, spatial decomposition in y and z direction
c parta/partb = input/output particle array
c parta(2,n) = position y of particle n in partition
c parta(3,n) = position z of particle n in partition
c npic = address offset for reordering particles
c npp = number of particles in partition
c noff(1) = lowermost global gridpoint in y in particle partition
c noff(2) = backmost global gridpoint in z in particle partition
c nyzp(1) = number of primary gridpoints in y in particle partition
c nyzp(2) = number of primary gridpoints in z in particle partition
c idimp = size of phase space = 6
c npmax = maximum number of particles in each partition
c nyzpm1 = max(nyzp(1)+1)*max(nyzp(2)+1)
c idds = dimensionality of domain decomposition
      implicit none
      integer npp, idimp, npmax, nyzpm1, idds
      real parta, partb
      integer npic, noff, nyzp
      dimension parta(idimp,npmax), partb(idimp,npmax)
      dimension npic(nyzpm1), noff(idds), nyzp(idds)
c local data
      integer i, j, k, l, n, nnoff, lnoff, nyp1, nyzp1, isum, ist, ip
      nnoff = noff(1)
      lnoff = noff(2)
      nyp1 = nyzp(1) + 1
      nyzp1 = nyp1*(nyzp(2) + 1)
c clear counter array
      do 10 k = 1, nyzp1
      npic(k) = 0
   10 continue
c find how many particles in each grid
      do 20 j = 1, npp
      n = parta(2,j)
      l = parta(3,j)
      l = n - nnoff + nyp1*(l - lnoff) + 1
      npic(l) = npic(l) + 1
   20 continue
c find address offset
      isum = 0
      do 30 k = 1, nyzp1
      ist = npic(k)
      npic(k) = isum
      isum = isum + ist
   30 continue
c find addresses of particles at each grid and reorder particles
      do 50 j = 1, npp
      n = parta(2,j)
      l = parta(3,j)
      l = n - nnoff + nyp1*(l - lnoff) + 1
      ip = npic(l) + 1
      do 40 i = 1, idimp
      partb(i,ip) = parta(i,j)
   40 continue
      npic(l) = ip
   50 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPCGUARD32XL(fxyz,nyzp,nx,ndim,nxe,nypmx,nzpmx,idds)
c replicate extended periodic vector field in x direction
c linear interpolation, for distributed data with 2D decomposition
c nyzp(1:2) = number of primary (complete) gridpoints in y/z
c nx = system length in xz direction
c ndim = leading dimension of field array fxyz
c nxe = first dimension of field array, must be >= nx+1
c nypmx = maximum size of particle partition in y, including guard cells
c nzpmx = maximum size of particle partition in z, including guard cells
c idds = dimensionality of domain decomposition = 2
      implicit none
      integer nx, ndim, nxe, nypmx, nzpmx, idds
      integer nyzp
      real fxyz
      dimension fxyz(ndim,nxe,nypmx,nzpmx), nyzp(idds)
c local data
      integer i, k, l, myp1, mzp1
c replicate edges of extended field
      myp1 = nyzp(1) + 1
      mzp1 = nyzp(2) + 1
      do 30 l = 1, mzp1
      do 20 k = 1, myp1
      do 10 i = 1, ndim
      fxyz(i,nx+1,k,l) = fxyz(i,1,k,l)
   10 continue
   20 continue
   30 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPAGUARD32XL(q,nyzp,nx,nxe,nypmx,nzpmx,idds)
c accumulate extended periodic scalar field in x direction
c linear interpolation, for distributed data with 2D decomposition
c nyzp(1:2) = number of primary (complete) gridpoints in y/z
c nx = system length in xz direction
c nxe = first dimension of field array, must be >= nx+1
c nypmx = maximum size of particle partition in y, including guard cells
c nzpmx = maximum size of particle partition in z, including guard cells
c idds = dimensionality of domain decomposition = 2
      implicit none
      integer nx, nxe, nypmx, nzpmx, idds
      integer nyzp
      real q
      dimension q(nxe,nypmx,nzpmx), nyzp(idds)
      integer k, l, myp1, mzp1
c accumulate edges of extended field
      myp1 = nyzp(1) + 1
      mzp1 = nyzp(2) + 1
      do 20 l = 1, mzp1
      do 10 k = 1, myp1
      q(1,k,l) = q(1,k,l) + q(nx+1,k,l)
      q(nx+1,k,l) = 0.0
   10 continue
   20 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPOIS332(q,fxyz,isign,ffc,ax,ay,az,affp,we,nx,ny,nz,   
     1kstrt,nvpy,nvpz,nzv,kxyp,kyzp,nzhd)
c this subroutine solves 3d poisson's equation in fourier space for
c force/charge (or convolution of electric field over particle shape)
c with periodic boundary conditions for distributed data,
c with 2D spatial decomposition
c for isign = 0, input: isign,ax,ay,az,affp,nx,ny,nz,kstrt,nvpy,nvpz,
c                       kxyp,kyzp,nzhd
c output: ffc
c for isign =/ 0, input: q,ffc,isign,nx,ny,nz,kstrt,nvpy,nvpz,nzv,kxyp,
c                        kyzp,nzhd
c output: fxyz,we
c approximate flop count is:
c 62*nxc*nyc*nzc + 33*(nxc*nyc + nxc*nzc + nyc*nzc)
c where nxc = (nx/2-1)/nvpy, nyc = (ny/2-1)/nvpz, nzc = nz/2 - 1, and
c nvpy/nvpz = number of procs in y/z
c the equation used is:
c fx(kx,ky,kz) = -sqrt(-1)*kx*g(kx,ky,kz)*q(kx,ky,kz)*s(kx,ky,kz),
c fy(kx,ky,kz) = -sqrt(-1)*ky*g(kx,ky,kz)*q(kx,ky,kz)*s(kx,ky,kz),
c fz(kx,ky,kz) = -sqrt(-1)*kz*g(kx,ky,kz)*q(kx,ky,kz)*s(kx,ky,kz),
c where kx = 2pi*j/nx, ky = 2pi*k/ny, kz = 2pi*l/nz, and
c j,k,l = fourier mode numbers,
c g(kx,ky,kz) = (affp/(kx**2+ky**2+kz**2))*s(kx,ky,kz),
c s(kx,ky,kz) = exp(-((kx*ax)**2+(ky*ay)**2+(kz*az)**2)/2), except for
c fx(kx=pi) = fy(kx=pi) = fz(kx=pi) = 0,
c fx(ky=pi) = fy(ky=pi) = fx(ky=pi) = 0,
c fx(kz=pi) = fy(kz=pi) = fz(kz=pi) = 0,
c fx(kx=0,ky=0,kz=0) = fy(kx=0,ky=0,kz=0) = fz(kx=0,ky=0,kz=0) = 0.
c q(l,j,k) = complex charge density for fourier mode jj-1,kk-1,l-1
c fxyz(1,l,j,k) = x component of force/charge
c fxyz(2,l,j,k) = y component of force/charge
c fxyz(3,l,j,k) = z component of force/charge
c all for fourier mode jj-1,kk-1,l-1, where jj = j + kxyp*js and
c kk = k + kyzp*ks, and MPI rank idproc = js + nvpy*ks
c if isign = 0, form factor array is prepared
c aimag(ffc(l,j,k)) = finite-size particle shape factor s
c real(ffc(l,j,k)) = potential green's function g
c for fourier mode jj-1,kk-1,l-1, where jj = j + kxyp*js and
c kk = k + kyzp*ks, and MPI rank idproc = js + nvpy*ks
c ax/ay/az = half-width of particle in x/y/z direction
c affp = normalization constant = nx*ny*nz/np,
c where np=number of particles
c electric field energy is also calculated, using
c we = nx*ny*nz*sum((affp/(kx**2+ky**2+kz**2))*
c    |q(kx,ky,kz)*s(kx,ky,kz)|**2)
c nx/ny/nz = system length in x/y/z direction
c kstrt = starting data block number
c nvpy/nvpz = number of real or virtual processors in y/z
c nzv = first dimension of field arrays, must be >= nz
c kxyp/kyzp = number of complex grids in each field partition in
c x/y direction
c nzhd = first dimension of form factor array, must be >= nzh
      implicit none
      integer isign, nx, ny, nz, kstrt, nvpy, nvpz, nzv, kxyp, kyzp
      integer nzhd
      real ax, ay, az, affp, we
      complex q, fxyz, ffc
      dimension q(nzv,kxyp,kyzp), fxyz(3,nzv,kxyp,kyzp)
      dimension ffc(nzhd,kxyp,kyzp)
c local data
      integer j, k, l, nxh, nyh, nzh, nz2, js, ks, joff, koff
      integer kxyps, kyzps, k1, l1
      real dnx, dny, dnz, dkx, dky, dkz, at1, at2, at3, at4, at5, at6
      complex zero, zt1, zt2
      double precision wp
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      nz2 = nz + 2
      dnx = 6.28318530717959/real(nx)
      dny = 6.28318530717959/real(ny)
      dnz = 6.28318530717959/real(nz)
      zero = cmplx(0.0,0.0)
c find processor id and offsets in y/z
c js/ks = processor co-ordinates in x/y => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      joff = kxyp*js
      kxyps = min(kxyp,max(0,nxh-joff))
      joff = joff - 1
      koff = kyzp*ks
      kyzps = min(kyzp,max(0,ny-koff))
      koff = koff - 1
      if (isign.ne.0) go to 40
      if (kstrt.gt.(nvpy*nvpz)) return
c prepare form factor array
      do 30 k = 1, kyzps
      k1 = k + koff
      if (k1.gt.nyh) k1 = k1 - ny
      dky = dny*real(k1)
      at1 = dky*dky
      at2 = (dky*ay)**2
      do 20 j = 1, kxyps
      dkx = dnx*real(j + joff)
      at3 = dkx*dkx + at1
      at4 = (dkx*ax)**2 + at2
      do 10 l = 1, nzh
      dkz = dnz*real(l - 1)
      at5 = dkz*dkz + at3
      at6 = exp(-.5*((dkz*az)**2 + at4))
      if (at5.eq.0.0) then
         ffc(l,j,k) = cmplx(affp,1.0)
      else
         ffc(l,j,k) = cmplx(affp*at6/at5,at6)
      endif
   10 continue
   20 continue
   30 continue
      return
c calculate force/charge and sum field energy
   40 wp = 0.0d0
      if (kstrt.gt.(nvpy*nvpz)) go to 180
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
      do 90 k = 1, kyzps
      k1 = k + koff
      if ((k1.gt.0).and.(k1.ne.nyh)) then
         if (k1.gt.nyh) k1 = k1 - ny
         dky = dny*real(k1)
         do 60 j = 1, kxyps
         dkx = dnx*real(j + joff)
         if ((j+joff).gt.0) then
            do 50 l = 2, nzh
            l1 = nz2 - l
            at1 = real(ffc(l,j,k))*aimag(ffc(l,j,k))
            at2 = dkx*at1
            at3 = dky*at1
            at4 = dnz*real(l - 1)*at1
            zt1 = cmplx(aimag(q(l,j,k)),-real(q(l,j,k)))
            zt2 = cmplx(aimag(q(l1,j,k)),-real(q(l1,j,k)))
            fxyz(1,l,j,k) = at2*zt1
            fxyz(2,l,j,k) = at3*zt1
            fxyz(3,l,j,k) = at4*zt1
            fxyz(1,l1,j,k) = at2*zt2
            fxyz(2,l1,j,k) = at3*zt2
            fxyz(3,l1,j,k) = -at4*zt2
            wp = wp + at1*(q(l,j,k)*conjg(q(l,j,k))
     1              + q(l1,j,k)*conjg(q(l1,j,k)))
   50       continue
c mode numbers kz = 0, nz/2
            l1 = nzh + 1
            at1 = real(ffc(1,j,k))*aimag(ffc(1,j,k))
            at2 = dkx*at1
            at3 = dky*at1
            zt1 = cmplx(aimag(q(1,j,k)),-real(q(1,j,k)))
            fxyz(1,1,j,k) = at2*zt1
            fxyz(2,1,j,k) = at3*zt1
            fxyz(3,1,j,k) = zero
            fxyz(1,l1,j,k) = zero
            fxyz(2,l1,j,k) = zero
            fxyz(3,l1,j,k) = zero
            wp = wp + at1*(q(1,j,k)*conjg(q(1,j,k)))
         endif
   60    continue
c mode numbers kx = 0, nx/2
         if (js.eq.0) then
c keep kx = 0
            if (k1.gt.0) then
               do 70 l = 2, nzh
               l1 = nz2 - l
               at1 = real(ffc(l,1,k))*aimag(ffc(l,1,k))
               at3 = dky*at1
               at4 = dnz*real(l - 1)*at1
               zt1 = cmplx(aimag(q(l,1,k)),-real(q(l,1,k)))
               zt2 = cmplx(aimag(q(l1,1,k)),-real(q(l1,1,k)))
               fxyz(1,l,1,k) = zero
               fxyz(2,l,1,k) = at3*zt1
               fxyz(3,l,1,k) = at4*zt1
               fxyz(1,l1,1,k) = zero
               fxyz(2,l1,1,k) = at3*zt2
               fxyz(3,l1,1,k) = -at4*zt2
               wp = wp + at1*(q(l,1,k)*conjg(q(l,1,k))
     1                 + q(l1,1,k)*conjg(q(l1,1,k)))
   70          continue
c mode numbers kz = 0, nz/2
               l1 = nzh + 1
               at1 = real(ffc(1,1,k))*aimag(ffc(1,1,k))
               at3 = dky*at1
               zt1 = cmplx(aimag(q(1,1,k)),-real(q(1,1,k)))
               fxyz(1,1,1,k) = zero
               fxyz(2,1,1,k) = at3*zt1
               fxyz(3,1,1,k) = zero
               fxyz(1,l1,1,k) = zero
               fxyz(2,l1,1,k) = zero
               fxyz(3,l1,1,k) = zero
               wp = wp + at1*(q(1,1,k)*conjg(q(1,1,k)))
c throw away kx = nx/2
            else
               do 80 l = 1, nz
               fxyz(1,l,1,k) = zero
               fxyz(2,l,1,k) = zero
               fxyz(3,l,1,k) = zero
   80          continue
            endif
         endif
      endif
   90 continue
c mode numbers ky = 0, ny/2
c keep ky = 0
      if (ks.eq.0) then
         do 110 j = 1, kxyps
         dkx = dnx*real(j + joff)
         if ((j+joff).gt.0) then
            do 100 l = 2, nzh
            l1 = nz2 - l
            at1 = real(ffc(l,j,1))*aimag(ffc(l,j,1))
            at2 = dkx*at1
            at4 = dnz*real(l - 1)*at1
            zt1 = cmplx(aimag(q(l,j,1)),-real(q(l,j,1)))
            zt2 = cmplx(aimag(q(l1,j,1)),-real(q(l1,j,1)))
            fxyz(1,l,j,1) = at2*zt1
            fxyz(2,l,j,1) = zero
            fxyz(3,l,j,1) = at4*zt1
            fxyz(1,l1,j,1) = at2*zt2
            fxyz(2,l1,j,1) = zero
            fxyz(3,l1,j,1) = -at4*zt2
            wp = wp + at1*(q(l,j,1)*conjg(q(l,j,1))
     1              + q(l1,j,1)*conjg(q(l1,j,1)))
  100       continue
c mode numbers kz = 0, nz/2
            l1 = nzh + 1
            at1 = real(ffc(1,j,1))*aimag(ffc(1,j,1))
            at2 = dkx*at1
            zt1 = cmplx(aimag(q(1,j,1)),-real(q(1,j,1)))
            fxyz(1,1,j,1) = at2*zt1
            fxyz(2,1,j,1) = zero
            fxyz(3,1,j,1) = zero
            fxyz(1,l1,j,1) = zero
            fxyz(2,l1,j,1) = zero
            fxyz(3,l1,j,1) = zero
            wp = wp + at1*(q(1,j,1)*conjg(q(1,j,1)))
         endif
  110    continue
c mode numbers kx = 0, nx/2
         if (js.eq.0) then
            do 120 l = 2, nzh
            l1 = nz2 - l
            at1 = real(ffc(l,1,1))*aimag(ffc(l,1,1))
            at4 = dnz*real(l - 1)*at1
            zt1 = cmplx(aimag(q(l,1,1)),-real(q(l,1,1)))
            fxyz(1,l,1,1) = zero
            fxyz(2,l,1,1) = zero
            fxyz(3,l,1,1) = at4*zt1
            fxyz(1,l1,1,1) = zero
            fxyz(2,l1,1,1) = zero
            fxyz(3,l1,1,1) = zero
            wp = wp + at1*(q(l,1,1)*conjg(q(l,1,1)))
  120       continue
c mode numbers kz = 0, nz/2
            l1 = nzh + 1
            fxyz(1,1,1,1) = zero
            fxyz(2,1,1,1) = zero
            fxyz(3,1,1,1) = zero
            fxyz(1,l1,1,1) = zero
            fxyz(2,l1,1,1) = zero
            fxyz(3,l1,1,1) = zero
         endif
      endif
c throw away ky = ny/2
      k1 = nyh/kyzp
      if (ks.eq.k1) then
         k1 = nyh - kyzp*k1 + 1
         do 140 j = 1, kxyps
         dkx = dnx*real(j + joff)
         if ((j+joff).gt.0) then
            do 130 l = 1, nz
            fxyz(1,l,j,k1) = zero
            fxyz(2,l,j,k1) = zero
            fxyz(3,l,j,k1) = zero
  130       continue
         endif
  140    continue
c mode numbers kx = 0, nx/2
         if (js.eq.0) then
            do 150 l = 1, nz
            fxyz(1,l,1,k1) = zero
            fxyz(2,l,1,k1) = zero
            fxyz(3,l,1,k1) = zero
  150       continue
         endif
      endif
  180 continue
      we = real(nx)*real(ny)*real(nz)*wp
      return
      end
c-----------------------------------------------------------------------
      subroutine WPFFT32RINIT(mixup,sct,indx,indy,indz,nxhyzd,nxyzhd)
c this subroutine calculates tables needed by a three dimensional
c real to complex fast fourier transform and its inverse.
c input: indx, indy, indz, nxhyzd, nxyzhd
c output: mixup, sct
c mixup = array of bit reversed addresses
c sct = sine/cosine table
c indx/indy/indz = exponent which determines length in x/y/z direction,
c where nx=2**indx, ny=2**indy, nz=2**indz
c nxhyzd = maximum of (nx/2,ny,nz)
c nxyzhd = one half of maximum of (nx,ny,nz)
c written by viktor k. decyk, ucla
      implicit none
      integer indx, indy, indz, nxhyzd, nxyzhd
      integer mixup
      complex sct
      dimension mixup(nxhyzd), sct(nxyzhd)
c local data
      integer indx1, ndx1yz, nx, ny, nz, nxyz, nxhyz, nxyzh
      integer j, k, lb, ll, jb, it
      real dnxyz, arg
      indx1 = indx - 1
      ndx1yz = max0(indx1,indy,indz)
      nx = 2**indx
      ny = 2**indy
      nz = 2**indz
      nxyz = max0(nx,ny,nz)
      nxhyz = 2**ndx1yz
c bit-reverse index table: mixup(j) = 1 + reversed bits of (j - 1)
      do 20 j = 1, nxhyz
      lb = j - 1
      ll = 0
      do 10 k = 1, ndx1yz
      jb = lb/2
      it = lb - 2*jb
      lb = jb
      ll = 2*ll + it
   10 continue
      mixup(j) = ll + 1
   20 continue
c sine/cosine table for the angles 2*n*pi/nxyz
      nxyzh = nxyz/2
      dnxyz = 6.28318530717959/real(nxyz)
      do 30 j = 1, nxyzh
      arg = dnxyz*real(j - 1)
      sct(j) = cmplx(cos(arg),-sin(arg))
   30 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine WPPFFT32R(f,g,h,bs,br,isign,ntpose,mixup,sct,ttp,indx, 
     1indy,indz,kstrt,nvpy,nvpz,nxvh,nyv,nzv,kxyp,kyp,kyzp,kzp,kxypd,   
     2kypd,kyzpd,kzpd,kzyp,nxhyzd,nxyzhd)
c wrapper function for 3d real to complex fft, with packed data
c parallelized with MPI
      implicit none
      integer isign, ntpose, indx, indy, indz, kstrt, nvpy, nvpz
      integer nxvh, nyv, nzv, kxyp, kyp, kyzp, kzp
      integer kxypd, kypd, kyzpd, kzpd, kzyp, nxhyzd, nxyzhd
      integer mixup
      real ttp
      complex f, g, h, bs, br, sct
      dimension f(nxvh,kypd,kzpd), g(nyv,kxypd,kzpd), h(nzv,kxypd,kyzpd)
      dimension bs(kxyp*kzyp,kzp), br(kxyp*kzyp,kzp)
      dimension mixup(nxhyzd), sct(nxyzhd)
c local data
      integer nxh, ny, nz, kypi, kxypi, js, ks, kxypp, kypp, kzpp, nvp
      real tp, tf
      double precision dtime
      data kypi, kxypi /1,1/
c calculate range of indices
      nxh = 2**(indx - 1)
      ny = 2**indy
      nz = 2**indz
c js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kxypp = min(kxyp,max(0,nxh-kxyp*js))
      kypp = min(kyp,max(0,ny-kyp*js))
      kzpp = min(kzp,max(0,nz-kzp*ks))
      nvp = nvpy*nvpz
c inverse fourier transform
      if (isign.lt.0) then
c perform x fft
         call PPFFT32RXX(f,isign,mixup,sct,indx,indy,indz,kstrt,nvp,kypi
     1,kypp,nxvh,kzpp,kypd,kzpd,nxhyzd,nxyzhd)
c transpose f array to g
         call PWTIMERA(-1,ttp,dtime)
         call PPTPOS3A(f,g,bs,br,nxh,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,nxvh,
     1nyv,kxypd,kypd,kzpd)
         call PWTIMERA(1,ttp,dtime)
c perform y fft
         call PPFFT32RXY(g,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,   
     1nvpz,kxypi,kxypp,nyv,kzpp,kxypd,kzpd,nxhyzd,nxyzhd)
c transpose g array to h
         call PWTIMERA(-1,tp,dtime)
         call PPTPOS3B(g,h,bs,br,nxh,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy,nvpz
     1,nyv,nzv,kxypd,kyzpd,kzpd)
         call PWTIMERA(1,tp,dtime)
c perform z fft
         call PPFFT32RXZ(h,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,   
     1nvpz,kxypi,kxypp,nzv,kyzp,kxypd,kyzpd,nxhyzd,nxyzhd)
c transpose h array to f
         if (ntpose.eq.0) then
            call PWTIMERA(-1,tf,dtime)
            call PPTPOS3B(h,g,br,bs,nxh,nz,ny,kxyp,kzp,kyzp,kstrt,nvpy, 
     1nvpz,nzv,nyv,kxypd,kzpd,kyzpd)
            call PPTPOS3A(g,f,br,bs,ny,nxh,nz,kyp,kxyp,kzp,kstrt,nvpy,  
     1nyv,nxvh,kypd,kxypd,kzpd)
            call PWTIMERA(1,tf,dtime)
         endif
c forward fourier transform
      else if (isign.gt.0) then
c transpose f array to h
         if (ntpose.eq.0) then
            call PWTIMERA(-1,tf,dtime)
            call PPTPOS3A(f,g,bs,br,nxh,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,  
     1nxvh,nyv,kxypd,kypd,kzpd)
            call PPTPOS3B(g,h,bs,br,nxh,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy, 
     1nvpz,nyv,nzv,kxypd,kyzpd,kzpd)
            call PWTIMERA(1,tf,dtime)
         endif
c perform z fft
         call PPFFT32RXZ(h,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,   
     1nvpz,kxypi,kxypp,nzv,kyzp,kxypd,kyzpd,nxhyzd,nxyzhd)
c transpose h array to g
         call PWTIMERA(-1,tp,dtime)
         call PPTPOS3B(h,g,br,bs,nxh,nz,ny,kxyp,kzp,kyzp,kstrt,nvpy,nvpz
     1,nzv,nyv,kxypd,kzpd,kyzpd)
         call PWTIMERA(1,tp,dtime)
c perform y fft
         call PPFFT32RXY(g,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,   
     1nvpz,kxypi,kxypp,nyv,kzpp,kxypd,kzpd,nxhyzd,nxyzhd)
c transpose g array to f
         call PWTIMERA(-1,ttp,dtime)
         call PPTPOS3A(g,f,br,bs,ny,nxh,nz,kyp,kxyp,kzp,kstrt,nvpy,nyv, 
     1nxvh,kypd,kxypd,kzpd)
         call PWTIMERA(1,ttp,dtime)
c perform x fft
         call PPFFT32RXX(f,isign,mixup,sct,indx,indy,indz,kstrt,nvp,kypi
     1,kypp,nxvh,kzpp,kypd,kzpd,nxhyzd,nxyzhd)
      endif
      ttp = ttp + tp
      if (ntpose.eq.0) ttp = ttp + tf
      return
      end
c-----------------------------------------------------------------------
      subroutine WPPFFT32R3(f,g,h,bs,br,isign,ntpose,mixup,sct,ttp,indx,
     1indy,indz,kstrt,nvpy,nvpz,nxvh,nyv,nzv,kxyp,kyp,kyzp,kzp,kxypd,   
     2kypd,kyzpd,kzpd,kzyp,nxhyzd,nxyzhd)
c wrapper function for 3 3d real to complex ffts, with packed data
c parallelized with MPI
      implicit none
      integer isign, ntpose, indx, indy, indz, kstrt, nvpy, nvpz
      integer nxvh, nyv, nzv, kxyp, kyp, kyzp, kzp
      integer kxypd, kypd, kyzpd, kzpd, kzyp, nxhyzd, nxyzhd
      integer mixup
      real ttp
      complex f, g, h, bs, br, sct
      dimension f(3,nxvh,kypd,kzpd), g(3,nyv,kxypd,kzpd)
      dimension h(3,nzv,kxypd,kyzpd)
      dimension bs(3,kxyp*kzyp,kzp), br(3,kxyp*kzyp,kzp)
      dimension mixup(nxhyzd), sct(nxyzhd)
c local data
      integer nxh, ny, nz, kypi, kxypi, js, ks, kxypp, kypp, kzpp, nvp
      real tp, tf
      double precision dtime
      data kypi, kxypi /1,1/
c calculate range of indices
      nxh = 2**(indx - 1)
      ny = 2**indy
      nz = 2**indz
c js/ks = processor co-ordinates in y/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kxypp = min(kxyp,max(0,nxh-kxyp*js))
      kypp = min(kyp,max(0,ny-kyp*js))
      kzpp = min(kzp,max(0,nz-kzp*ks))
      nvp = nvpy*nvpz
c inverse fourier transform
      if (isign.lt.0) then
c perform x fft
         call PPFFT32R3XX(f,isign,mixup,sct,indx,indy,indz,kstrt,nvp,   
     1kypi,kypp,nxvh,kzpp,kypd,kzpd,nxhyzd,nxyzhd)
c transpose f array to g
         call PWTIMERA(-1,ttp,dtime)
         call PPNTPOS3A(f,g,bs,br,nxh,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,3,  
     1nxvh,nyv,kxypd,kypd,kzpd)
         call PWTIMERA(1,ttp,dtime)
c perform y fft
         call PPFFT32R3XY(g,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,  
     1nvpz,kxypi,kxypp,nyv,kzpp,kxypd,kzpd,nxhyzd,nxyzhd)
c transpose g array to h
         call PWTIMERA(-1,tp,dtime)
         call PPNTPOS3B(g,h,bs,br,nxh,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy,   
     1nvpz,3,nyv,nzv,kxypd,kyzpd,kzpd)
         call PWTIMERA(1,tp,dtime)
c perform z fft
         call PPFFT32R3XZ(h,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,  
     1nvpz,kxypi,kxypp,nzv,kyzp,kxypd,kyzpd,nxhyzd,nxyzhd)
c transpose h array to f
         if (ntpose.eq.0) then
            call PWTIMERA(-1,tf,dtime)
            call PPNTPOS3B(h,g,br,bs,nxh,nz,ny,kxyp,kzp,kyzp,kstrt,nvpy,
     1nvpz,3,nzv,nyv,kxypd,kzpd,kyzpd)
            call PPNTPOS3A(g,f,br,bs,ny,nxh,nz,kyp,kxyp,kzp,kstrt,nvpy,3
     1,nyv,nxvh,kypd,kxypd,kzpd)
            call PWTIMERA(1,tf,dtime)
         endif
c forward fourier transform
      else if (isign.gt.0) then
c transpose f array to h
         if (ntpose.eq.0) then
            call PWTIMERA(-1,tf,dtime)
            call PPNTPOS3A(f,g,bs,br,nxh,ny,nz,kxyp,kyp,kzp,kstrt,nvpy,3
     1,nxvh,nyv,kxypd,kypd,kzpd)
            call PPNTPOS3B(g,h,bs,br,nxh,ny,nz,kxyp,kyzp,kzp,kstrt,nvpy,
     1nvpz,3,nyv,nzv,kxypd,kyzpd,kzpd)
            call PWTIMERA(1,tf,dtime)
         endif
c perform z fft
         call PPFFT32R3XZ(h,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,  
     1nvpz,kxypi,kxypp,nzv,kyzp,kxypd,kyzpd,nxhyzd,nxyzhd)
c transpose h array to g
         call PWTIMERA(-1,tp,dtime)
         call PPNTPOS3B(h,g,br,bs,nxh,nz,ny,kxyp,kzp,kyzp,kstrt,nvpy,   
     1nvpz,3,nzv,nyv,kxypd,kzpd,kyzpd)
         call PWTIMERA(1,tp,dtime)
c perform y fft
         call PPFFT32R3XY(g,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,  
     1nvpz,kxypi,kxypp,nyv,kzpp,kxypd,kzpd,nxhyzd,nxyzhd)
c transpose g array to f
         call PWTIMERA(-1,ttp,dtime)
         call PPNTPOS3A(g,f,br,bs,ny,nxh,nz,kyp,kxyp,kzp,kstrt,nvpy,3,  
     1nyv,nxvh,kypd,kxypd,kzpd)
         call PWTIMERA(1,ttp,dtime)
c perform x fft
         call PPFFT32R3XX(f,isign,mixup,sct,indx,indy,indz,kstrt,nvp,   
     1kypi,kypp,nxvh,kzpp,kypd,kzpd,nxhyzd,nxyzhd)
      endif
      ttp = ttp + tp
      if (ntpose.eq.0) ttp = ttp + tf
      return
      end
c-----------------------------------------------------------------------
      subroutine PPFFT32RXX(f,isign,mixup,sct,indx,indy,indz,kstrt,nvp, 
     1kypi,kypp,nxvh,kzpp,kypd,kzpd,nxhyzd,nxyzhd)
c this subroutine performs the x part of a three dimensional real to
c complex fast fourier transform and its inverse for a subset of y and z
c using complex arithmetic, for data which is distributed in blocks,
c with 2D spatial decomposition
c for isign = (-1,1), input: all, output: f
c for isign = -1, approximate flop count: N*(5*log2(N) + 19/2)/nvp
c for isign = 1,  approximate flop count: N*(5*log2(N) + 15/2)/nvp
c where N = (nx/2)*ny*nz, and nvp = number of procs
c indx/indy/indz = exponent which determines length in x/y/z direction,
c where nx=2**indx, ny=2**indy, nz=2**indz
c if isign = -1, an inverse fourier transform is performed
c f(n,k,i) = (1/nx*ny*nz)*sum(f(j,k,i)*exp(-sqrt(-1)*2pi*n*j/nx))
c if isign = 1, a forward fourier transform is performed
c f(n,k,i) = sum(f(j,k,i)*exp(sqrt(-1)*2pi*n*j/nx))
c kstrt = starting data block number
c nvp = number of real or virtual processors
c kypi = initial y index used
c kypp = number of y indices used
c nxvh = first dimension of f
c kzpp = number of z indices used
c kypd = second dimension of f
c kzpd = third dimension of f
c mixup = array of bit reversed addresses
c sct = sine/cosine table
c nxhyzd = maximum of (nx/2,ny,nz)
c nxyzhd = one half of maximum of (nx,ny,nz)
c final fourier coefficients are stored as follows:
c h(l,j,k) = mode jj-1,kk-1,l, where jj = j + kxyp*js, kk = k + kyzp*ks
c and MPI rank idproc = js + nvpy*ks
c 1 <= jj <= nx/2, 1 <= kk <= ny, and 1 <= l <= nz, except for
c h(l,1,k) = mode nx/2,kk-1,l-1, where ny/2+2 <= kk <= ny, 1 <= l <= nz,
c the following are located on node js = 0 and ks = 0:
c h(l,1,1) = mode nx/2,0,l-1, where 2 <= l <= nz/2
c imag(h(1,1,1)) = real part of mode nx/2,0,0
c imag(h(nz/2+1,1,1)) = real part of mode nx/2,0,nz/2
c the following are located on node js = 0 and ks = nyh/kyzp:
c h(l,1,ny/2+1) = mode nx/2,ny/2,l-1, where nz/2+2 <= l <= nz, and
c imag(h(1,1,ny/2+1)) = real part of mode nx/2,ny/2,0
c imag(h(nz/2+1,1,ny/2+1)) = real part of mode nx/2,ny/2,nz/2
c using jpl storage convention, as described in:
c E. Huang, P. C. Liewer, V. K. Decyk, and R. D. Ferraro, "Concurrent
c Three-Dimensional Fast Fourier Transform Algorithms for Coarse-Grained
c Distributed Memory Parallel Computers," Caltech CRPC Report 217-50,
c December 1993.
c written by viktor k. decyk, ucla
c parallel, RISC optimized version
      implicit none
      integer isign, indx, indy, indz, kstrt, nvp, kypi, kypp, nxvh
      integer kzpp, kypd, kzpd, nxhyzd, nxyzhd
      integer mixup
      complex f, sct
      dimension f(nxvh,kypd,kzpd)
      dimension mixup(nxhyzd), sct(nxyzhd)
c local data
      integer indx1, ndx1yz, nx, nxh, nxhh, nxh2, ny, nz, nxyz, nxhyz
      integer j, k, l, i, n, ns, ns2, km, kmr, k1, k2, j1, j2
      integer nrx, nry, kypt
      real ani
      complex s, t, t1
      if (isign.eq.0) return
      indx1 = indx - 1
      ndx1yz = max0(indx1,indy,indz)
      nx = 2**indx
      nxh = nx/2
      nxhh = nx/4
      nxh2 = nxh + 2
      ny = 2**indy
      nz = 2**indz
      nxyz = max0(nx,ny,nz)
      nxhyz = 2**ndx1yz
      kypt = kypi + kypp - 1
      if (kstrt.gt.nvp) return
      if (isign.gt.0) go to 110
c inverse fourier transform
      ani = 0.5/(real(nx)*real(ny)*real(nz))
      do 100 n = 1, kzpp
      nrx = nxhyz/nxh
c bit-reverse array elements in x
      do 20 j = 1, nxh
      j1 = (mixup(j) - 1)/nrx + 1
      if (j.ge.j1) go to 20
      do 10 i = kypi, kypt
      t = f(j1,i,n)
      f(j1,i,n) = f(j,i,n)
      f(j,i,n) = t
   10 continue
   20 continue
c first transform in x
      nrx = nxyz/nxh
      do 60 l = 1, indx1
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nxhh/ns
      kmr = km*nrx
      do 50 i = kypi, kypt
      do 40 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 30 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = sct(1+kmr*(j-1))
      t = s*f(j2,i,n)
      f(j2,i,n) = f(j1,i,n) - t
      f(j1,i,n) = f(j1,i,n) + t
   30 continue
   40 continue
   50 continue
   60 continue
c unscramble coefficients and normalize
      kmr = nxyz/nx
      nry = nxhyz/ny
      do 80 k = kypi, kypt
      do 70 j = 2, nxhh
      t1 = cmplx(aimag(sct(1+kmr*(j-1))),-real(sct(1+kmr*(j-1))))
      t = conjg(f(nxh2-j,k,n))
      s = f(j,k,n) + t
      t = (f(j,k,n) - t)*t1
      f(j,k,n) = ani*(s + t)
      f(nxh2-j,k,n) = ani*conjg(s - t)
   70 continue
   80 continue
      do 90 k = kypi, kypt
      f(1,k,n) = 2.0*ani*cmplx(real(f(1,k,n)) + aimag(f(1,k,n)),
     1                         real(f(1,k,n)) - aimag(f(1,k,n)))
      if (nxhh.gt.0) f(nxhh+1,k,n) = 2.0*ani*conjg(f(nxhh+1,k,n))
   90 continue
  100 continue
      return
c forward fourier transform
  110 do 210 n = 1, kzpp
c scramble coefficients
      kmr = nxyz/nx
      do 130 k = kypi, kypt
      do 120 j = 2, nxhh
      t1 = cmplx(aimag(sct(1+kmr*(j-1))),real(sct(1+kmr*(j-1))))
      t = conjg(f(nxh2-j,k,n))
      s = f(j,k,n) + t
      t = (f(j,k,n) - t)*t1
      f(j,k,n) = s + t
      f(nxh2-j,k,n) = conjg(s - t)
  120 continue
  130 continue
      do 140 k = kypi, kypt
      f(1,k,n) = cmplx(real(f(1,k,n)) + aimag(f(1,k,n)),
     1                 real(f(1,k,n)) - aimag(f(1,k,n)))
      if (nxhh.gt.0) f(nxhh+1,k,n) = 2.0*conjg(f(nxhh+1,k,n))
  140 continue
      nrx = nxhyz/nxh
c bit-reverse array elements in x
      do 160 j = 1, nxh
      j1 = (mixup(j) - 1)/nrx + 1
      if (j.ge.j1) go to 160
      do 150 i = kypi, kypt
      t = f(j1,i,n)
      f(j1,i,n) = f(j,i,n)
      f(j,i,n) = t
  150 continue
  160 continue
c finally transform in x
      nrx = nxyz/nxh
      do 200 l = 1, indx1
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nxhh/ns
      kmr = km*nrx
      do 190 i = kypi, kypt
      do 180 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 170 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = conjg(sct(1+kmr*(j-1)))
      t = s*f(j2,i,n)
      f(j2,i,n) = f(j1,i,n) - t
      f(j1,i,n) = f(j1,i,n) + t
  170 continue
  180 continue
  190 continue
  200 continue
  210 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPFFT32RXY(g,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,
     1nvpz,kxypi,kxypp,nyv,kzpp,kxypd,kzpd,nxhyzd,nxyzhd)
c this subroutine performs the y part of a three dimensional real to
c complex fast fourier transform and its inverse for a subset of x and z
c using complex arithmetic, for data which is distributed in blocks,
c with 2D spatial decomposition
c for isign = (-1,1), input: all, output: g
c for isign = -1, approximate flop count: N*(5*log2(N) + 19/2)/nvp
c for isign = 1,  approximate flop count: N*(5*log2(N) + 15/2)/nvp
c where N = (nx/2)*ny*nz, and nvp = number of procs
c indx/indy/indz = exponent which determines length in x/y/z direction,
c where nx=2**indx, ny=2**indy, nz=2**indz
c if isign = -1, an inverse fourier transform is performed
c g(m,j,i) = sum(g(k,j,i)*exp(-sqrt(-1)*2pi*m*k/ny))
c if isign = 1, a forward fourier transform is performed
c g(m,j,i) = sum(g(k,j,i)*exp(sqrt(-1)*2pi*m*k/ny))
c kstrt = starting data block number
c nvpy/nvpz = number of real or virtual processors in y/z
c kxypi = initial x index used
c kxypp = number of x indices used
c nyv = first dimension of g
c kzpp = number of z indices used
c kxypd = second dimension of g
c kzpd = third dimension of g
c mixup = array of bit reversed addresses
c sct = sine/cosine table
c nxhyzd = maximum of (nx/2,ny,nz)
c nxyzhd = one half of maximum of (nx,ny,nz)
c final fourier coefficients are stored as follows:
c h(l,j,k) = mode jj-1,kk-1,l, where jj = j + kxyp*js, kk = k + kyzp*ks
c and MPI rank idproc = js + nvpy*ks
c 1 <= jj <= nx/2, 1 <= kk <= ny, and 1 <= l <= nz, except for
c h(l,1,k) = mode nx/2,kk-1,l-1, where ny/2+2 <= kk <= ny, 1 <= l <= nz,
c the following are located on node js = 0 and ks = 0:
c h(l,1,1) = mode nx/2,0,l-1, where 2 <= l <= nz/2
c imag(h(1,1,1)) = real part of mode nx/2,0,0
c imag(h(nz/2+1,1,1)) = real part of mode nx/2,0,nz/2
c the following are located on node js = 0 and ks = nyh/kyzp:
c h(l,1,ny/2+1) = mode nx/2,ny/2,l-1, where nz/2+2 <= l <= nz, and
c imag(h(1,1,ny/2+1)) = real part of mode nx/2,ny/2,0
c imag(h(nz/2+1,1,ny/2+1)) = real part of mode nx/2,ny/2,nz/2
c using jpl storage convention, as described in:
c E. Huang, P. C. Liewer, V. K. Decyk, and R. D. Ferraro, "Concurrent
c Three-Dimensional Fast Fourier Transform Algorithms for Coarse-Grained
c Distributed Memory Parallel Computers," Caltech CRPC Report 217-50,
c December 1993.
c written by viktor k. decyk, ucla
c parallel, RISC optimized version
      implicit none
      integer isign, indx, indy, indz, kstrt, nvpy, nvpz, kxypi, kxypp
      integer nyv, kzpp, kxypd, kzpd, nxhyzd, nxyzhd
      integer mixup
      complex g, sct
      dimension g(nyv,kxypd,kzpd)
      dimension mixup(nxhyzd), sct(nxyzhd)
c local data
      integer indx1, ndx1yz, nx, nxh, ny, nyh, ny2, nz, nxyz, nxhyz
      integer j, k, l, i, n, ns, ns2, km, kmr, k1, k2, j1, j2
      integer js, ks, nry, kxypt
      complex s, t
      if (isign.eq.0) return
      indx1 = indx - 1
      ndx1yz = max0(indx1,indy,indz)
      nx = 2**indx
      nxh = nx/2
      ny = 2**indy
      nyh = max(1,ny/2)
      ny2 = ny + 2
      nz = 2**indz
      nxyz = max0(nx,ny,nz)
      nxhyz = 2**ndx1yz
      kxypt = kxypi + kxypp - 1
c js/ks = processor co-ordinates in x/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      if (kstrt.gt.(nvpy*nvpz)) return
      if (isign.gt.0) go to 100
c inverse fourier transform
      do 70 n = 1, kzpp
      nry = nxhyz/ny
c bit-reverse array elements in y
      do 20 k = 1, ny
      k1 = (mixup(k) - 1)/nry + 1
      if (k.ge.k1) go to 20
      do 10 i = kxypi, kxypt
      t = g(k1,i,n)
      g(k1,i,n) = g(k,i,n)
      g(k,i,n) = t
   10 continue
   20 continue
c then transform in y
      nry = nxyz/ny
      do 60 l = 1, indy
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nyh/ns
      kmr = km*nry
      do 50 i = kxypi, kxypt
      do 40 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 30 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = sct(1+kmr*(j-1))
      t = s*g(j2,i,n)
      g(j2,i,n) = g(j1,i,n) - t
      g(j1,i,n) = g(j1,i,n) + t
   30 continue
   40 continue
   50 continue
   60 continue
   70 continue
c unscramble modes kx = 0, nx/2
      if (js.gt.0) return
      if (kxypi.eq.1) then
         do 90 n = 1, kzpp
         do 80 k = 2, nyh
         s = g(ny2-k,1,n)
         g(ny2-k,1,n) = 0.5*cmplx(aimag(g(k,1,n) + s),
     1                            real(g(k,1,n) - s))
         g(k,1,n) = 0.5*cmplx(real(g(k,1,n) + s),aimag(g(k,1,n) - s))
   80    continue
   90    continue
      endif
      return
c forward fourier transform
c scramble modes kx = 0, nx/2
  100 if (js.gt.0) go to 130
      if (kxypi.eq.1) then
         do 120 n = 1, kzpp
         do 110 k = 2, nyh
         s = cmplx(aimag(g(ny2-k,1,n)),real(g(ny2-k,1,n)))
         g(ny2-k,1,n) = conjg(g(k,1,n) - s)
         g(k,1,n) = g(k,1,n) + s
  110    continue
  120    continue
      endif
  130 do 200 n = 1, kzpp
      nry = nxhyz/ny
c bit-reverse array elements in y
      do 150 k = 1, ny
      k1 = (mixup(k) - 1)/nry + 1
      if (k.ge.k1) go to 150
      do 140 i = kxypi, kxypt
      t = g(k1,i,n)
      g(k1,i,n) = g(k,i,n)
      g(k,i,n) = t
  140 continue
  150 continue
c then transform in y
      nry = nxyz/ny
      do 190 l = 1, indy
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nyh/ns
      kmr = km*nry
      do 180 i = kxypi, kxypt
      do 170 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 160 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = conjg(sct(1+kmr*(j-1)))
      t = s*g(j2,i,n)
      g(j2,i,n) = g(j1,i,n) - t
      g(j1,i,n) = g(j1,i,n) + t
  160 continue
  170 continue
  180 continue
  190 continue
  200 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPFFT32RXZ(h,isign,mixup,sct,indx,indy,indz,kstrt,nvpy,
     1nvpz,kxypi,kxypp,nzv,kyzp,kxypd,kyzpd,nxhyzd,nxyzhd)
c this subroutine performs the z part of a three dimensional real to
c complex fast fourier transform and its inverse for a subset of x and y
c using complex arithmetic, for data which is distributed in blocks,
c with 2D spatial decomposition
c for isign = (-1,1), input: all, output: h
c for isign = -1, approximate flop count: N*(5*log2(N) + 19/2)/nvp
c for isign = 1,  approximate flop count: N*(5*log2(N) + 15/2)/nvp
c where N = (nx/2)*ny*nz, and nvp = number of procs
c indx/indy/indz = exponent which determines length in x/y/z direction,
c where nx=2**indx, ny=2**indy, nz=2**indz
c if isign = -1, an inverse fourier transform is performed
c h(l,n,m) = sum(h(i,j,k)*exp(-sqrt(-1)*2pi*l*i/nz))
c if isign = 1, a forward fourier transform is performed
c h(l,n,m) = sum(h(i,j,k)*exp(sqrt(-1)*2pi*ll*ii/nz))
c kstrt = starting data block number
c nvpy/nvpz = number of real or virtual processors in y/z
c kxypi = initial x index used
c kxypp = number of x indices used
c nzv = first dimension of h
c kyzpp = number of y indices used
c kxypd = second dimension of h
c kyzpd = third dimension of h
c mixup = array of bit reversed addresses
c sct = sine/cosine table
c nxhyzd = maximum of (nx/2,ny,nz)
c nxyzhd = one half of maximum of (nx,ny,nz)
c final fourier coefficients are stored as follows:
c h(l,j,k) = mode jj-1,kk-1,l, where jj = j + kxyp*js, kk = k + kyzp*ks
c and MPI rank idproc = js + nvpy*ks
c 1 <= jj <= nx/2, 1 <= kk <= ny, and 1 <= l <= nz, except for
c h(l,1,k) = mode nx/2,kk-1,l-1, where ny/2+2 <= kk <= ny, 1 <= l <= nz,
c the following are located on node js = 0 and ks = 0:
c h(l,1,1) = mode nx/2,0,l-1, where 2 <= l <= nz/2
c imag(h(1,1,1)) = real part of mode nx/2,0,0
c imag(h(nz/2+1,1,1)) = real part of mode nx/2,0,nz/2
c the following are located on node js = 0 and ks = nyh/kyzp:
c h(l,1,ny/2+1) = mode nx/2,ny/2,l-1, where nz/2+2 <= l <= nz, and
c imag(h(1,1,ny/2+1)) = real part of mode nx/2,ny/2,0
c imag(h(nz/2+1,1,ny/2+1)) = real part of mode nx/2,ny/2,nz/2
c using jpl storage convention, as described in:
c E. Huang, P. C. Liewer, V. K. Decyk, and R. D. Ferraro, "Concurrent
c Three-Dimensional Fast Fourier Transform Algorithms for Coarse-Grained
c Distributed Memory Parallel Computers," Caltech CRPC Report 217-50,
c December 1993.
c written by viktor k. decyk, ucla
c parallel, RISC optimized version
      implicit none
      integer isign, indx, indy, indz, kstrt, nvpy, nvpz, kxypi, kxypp
      integer nzv, kyzp, kxypd, kyzpd, nxhyzd, nxyzhd
      integer mixup
      complex h, sct
      dimension h(nzv,kxypd,kyzpd)
      dimension mixup(nxhyzd), sct(nxyzhd)
c local data
      integer indx1, ndx1yz, nx, nxh, ny, nyh, nz, nzh, nz2, nxyz, nxhyz
      integer j, k, l, i, n, ns, ns2, km, kmr, k1, k2, j1, j2
      integer l1, js, ks, nrz, kxypt, kyzpp, kyzb
      complex s, t
      indx1 = indx - 1
      ndx1yz = max0(indx1,indy,indz)
      nx = 2**indx
      nxh = nx/2
      ny = 2**indy
      nyh = max(1,ny/2)
      nz = 2**indz
      nzh = max(1,nz/2)
      nz2 = nz + 2
      nxyz = max0(nx,ny,nz)
      nxhyz = 2**ndx1yz
      kxypt = kxypi + kxypp - 1
c js/ks = processor co-ordinates in x/y => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kyzpp = min(kyzp,max(0,ny-kyzp*ks))
      if (kstrt.gt.(nvpy*nvpz)) return
      if (isign.gt.0) go to 100
c inverse fourier transform
      do 70 n = 1, kyzpp
      nrz = nxhyz/nz
c bit-reverse array elements in z
      do 20 l = 1, nz
      l1 = (mixup(l) - 1)/nrz + 1
      if (l.ge.l1) go to 20
      do 10 i = kxypi, kxypt
      t = h(l1,i,n)
      h(l1,i,n) = h(l,i,n)
      h(l,i,n) = t
   10 continue
   20 continue
c finally transform in z
      nrz = nxyz/nz
      do 60 l = 1, indz
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nzh/ns
      kmr = km*nrz
      do 50 i = kxypi, kxypt
      do 40 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 30 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = sct(1+kmr*(j-1))
      t = s*h(j2,i,n)
      h(j2,i,n) = h(j1,i,n) - t
      h(j1,i,n) = h(j1,i,n) + t
   30 continue
   40 continue
   50 continue
   60 continue
   70 continue
c unscramble modes kx = 0, nx/2
      if (js.gt.0) return
      if (ks.eq.0) then
         if (kxypi.eq.1) then
            do 80 n = 2, nzh
            s = h(nz2-n,1,1)
            h(nz2-n,1,1) = 0.5*cmplx(aimag(h(n,1,1) + s),
     1                               real(h(n,1,1) - s))
            h(n,1,1) = 0.5*cmplx(real(h(n,1,1) + s),aimag(h(n,1,1) - s))
   80       continue
         endif
      endif
      kyzb = nyh/kyzp
      if (ks.eq.kyzb) then
         k1 = nyh - kyzb*kyzp + 1
         if (kxypi.eq.1) then
            do 90 n = 2, nzh
            s = h(nz2-n,1,k1)
            h(nz2-n,1,k1) = 0.5*cmplx(aimag(h(n,1,k1) + s),
     1                                real(h(n,1,k1) - s))
            h(n,1,k1) = 0.5*cmplx(real(h(n,1,k1) + s),
     1                            aimag(h(n,1,k1) - s))
   90       continue
        endif
      endif
      return
c forward fourier transform
c scramble modes kx = 0, nx/2
  100 if (js.gt.0) go to 130
      if (ks.eq.0) then
         if (kxypi.eq.1) then
            do 110 n = 2, nzh
            s = cmplx(aimag(h(nz2-n,1,1)),real(h(nz2-n,1,1)))
            h(nz2-n,1,1) = conjg(h(n,1,1) - s)
            h(n,1,1) = h(n,1,1) + s
  110       continue
         endif
      endif
      kyzb = nyh/kyzp
      if (ks.eq.kyzb) then
         k1 = nyh - kyzb*kyzp + 1
         if (kxypi.eq.1) then
            do 120 n = 2, nzh
            s = cmplx(aimag(h(nz2-n,1,k1)),real(h(nz2-n,1,k1)))
            h(nz2-n,1,k1) = conjg(h(n,1,k1) - s)
            h(n,1,k1) = h(n,1,k1) + s
  120       continue
         endif
      endif
  130 do 200 n = 1, kyzpp
      nrz = nxhyz/nz
c bit-reverse array elements in z
      do 150 l = 1, nz
      l1 = (mixup(l) - 1)/nrz + 1
      if (l.ge.l1) go to 150
      do 140 i = kxypi, kxypt
      t = h(l1,i,n)
      h(l1,i,n) = h(l,i,n)
      h(l,i,n) = t
  140 continue
  150 continue
c first transform in z
      nrz = nxyz/nz
      do 190 l = 1, indz
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nzh/ns
      kmr = km*nrz
      do 180 i = kxypi, kxypt
      do 170 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 160 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = conjg(sct(1+kmr*(j-1)))
      t = s*h(j2,i,n)
      h(j2,i,n) = h(j1,i,n) - t
      h(j1,i,n) = h(j1,i,n) + t
  160 continue
  170 continue
  180 continue
  190 continue
  200 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPFFT32R3XX(f,isign,mixup,sct,indx,indy,indz,kstrt,nvp,
     1kypi,kypp,nxvh,kzpp,kypd,kzpd,nxhyzd,nxyzhd)
c this subroutine performs the x part of 3 three dimensional real to
c complex fast fourier transforms and their inverses for a subset of
c y and z, using complex arithmetic,
c for data which is distributed in blocks, with 2D spatial decomposition
c for isign = (-1,1), input: all, output: f
c for isign = -1, approximate flop count: N*(5*log2(N) + 19/2)/nvp
c for isign = 1,  approximate flop count: N*(5*log2(N) + 15/2)/nvp
c where N = (nx/2)*ny*nz, and nvp = number of procs
c indx/indy/indz = exponent which determines length in x/y/z direction,
c where nx=2**indx, ny=2**indy, nz=2**indz
c if isign = -1, an inverse fourier transform is performed
c f(1:3,n,k,i) = (1/nx*ny*nz)*sum(f(1:3,j,k,i)*
c                                 exp(-sqrt(-1)*2pi*n*j/nx))
c if isign = 1, a forward fourier transform is performed
c f(1:3,n,k,i) = sum(f(1:3,j,k,i)*exp(sqrt(-1)*2pi*n*j/nx))
c kstrt = starting data block number
c nvp = number of real or virtual processors
c kypi = initial y index used
c kypp = number of y indices used
c nxvh = first dimension of f
c kzpp = number of z indices used
c kypd = second dimension of f
c kzpd = third dimension of f
c mixup = array of bit reversed addresses
c sct = sine/cosine table
c nxhyzd = maximum of (nx/2,ny,nz)
c nxyzhd = one half of maximum of (nx,ny,nz)
c the real data is stored in a complex array of length nx/2, ny, nz
c with the odd/even x points stored in the real/imaginary parts.
c final fourier coefficients are stored as follows:
c h(1:3,l,j,k) = mode jj-1,kk-1,l, where jj = j + kxyp*js,
c kk = k + kyzp*ks, and MPI rank idproc = js + nvpy*ks
c 1 <= jj <= nx/2, 1 <= kk <= ny, and 1 <= l <= nz, except for
c h(1:3,l,1,k) = mode nx/2,kk-1,l-1,
c where ny/2+2 <= kk <= ny, 1 <= l <= nz,
c the following are located on node js = 0 and ks = 0:
c h(1:3,l,1,1) = mode nx/2,0,l-1, where 2 <= l <= nz/2
c imag(h(1:3,1,1,1)) = real part of mode nx/2,0,0
c imag(h(1:3,nz/2+1,1,1)) = real part of mode nx/2,0,nz/2
c the following are located on node js = 0 and ks = nyh/kyzp:
c h(1:3,l,1,ny/2+1) = mode nx/2,ny/2,l-1, where nz/2+2 <= l <= nz, and
c imag(h(1:3,1,1,ny/2+1)) = real part of mode nx/2,ny/2,0
c imag(h(1:3,nz/2+1,1,ny/2+1)) = real part of mode nx/2,ny/2,nz/2
c using jpl storage convention, as described in:
c E. Huang, P. C. Liewer, V. K. Decyk, and R. D. Ferraro, "Concurrent
c Three-Dimensional Fast Fourier Transform Algorithms for Coarse-Grained
c Distributed Memory Parallel Computers," Caltech CRPC Report 217-50,
c December 1993.
c written by viktor k. decyk, ucla
c parallel, RISC optimized version
      implicit none
      integer isign, indx, indy, indz, kstrt, nvp, kypi, kypp, nxvh
      integer kzpp, kypd, kzpd, nxhyzd, nxyzhd
      integer mixup
      complex f, sct
      dimension f(3,nxvh,kypd,kzpd)
      dimension mixup(nxhyzd), sct(nxyzhd)
c local data
      integer indx1, ndx1yz, nx, nxh, nxhh, nxh2, ny, nz, nxyz, nxhyz
      integer j, k, l, i, n, ns, ns2, km, kmr, k1, k2, j1, j2, jj
      integer nrx, nry, kypt
      real ani, at1, at2
      complex s, t, t1, t2, t3
      if (isign.eq.0) return
      indx1 = indx - 1
      ndx1yz = max0(indx1,indy,indz)
      nx = 2**indx
      nxh = nx/2
      nxhh = nx/4
      nxh2 = nxh + 2
      ny = 2**indy
      nz = 2**indz
      nxyz = max0(nx,ny,nz)
      nxhyz = 2**ndx1yz
      kypt = kypi + kypp - 1
      if (kstrt.gt.nvp) return
      if (isign.gt.0) go to 150
c inverse fourier transform
      ani = 0.5/(real(nx)*real(ny)*real(nz))
      do 140 n = 1, kzpp
c swap complex components
      do 20 i = kypi, kypt
      do 10 j = 1, nxh
      at1 = real(f(3,j,i,n))
      f(3,j,i,n) = cmplx(real(f(2,j,i,n)),aimag(f(3,j,i,n)))
      at2 = aimag(f(2,j,i,n))
      f(2,j,i,n) = cmplx(aimag(f(1,j,i,n)),at1)
      f(1,j,i,n) = cmplx(real(f(1,j,i,n)),at2)
   10 continue
   20 continue
      nrx = nxhyz/nxh
c bit-reverse array elements in x
      do 40 j = 1, nxh
      j1 = (mixup(j) - 1)/nrx + 1
      if (j.ge.j1) go to 40
      do 30 i = kypi, kypt
      t1 = f(1,j1,i,n)
      t2 = f(2,j1,i,n)
      t3 = f(3,j1,i,n)
      f(1,j1,i,n) = f(1,j,i,n)
      f(2,j1,i,n) = f(2,j,i,n)
      f(3,j1,i,n) = f(3,j,i,n)
      f(1,j,i,n) = t1
      f(2,j,i,n) = t2
      f(3,j,i,n) = t3
   30 continue
   40 continue
c first transform in x
      nrx = nxyz/nxh
      do 80 l = 1, indx1
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nxhh/ns
      kmr = km*nrx
      do 70 i = kypi, kypt
      do 60 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 50 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = sct(1+kmr*(j-1))
      t1 = s*f(1,j2,i,n)
      t2 = s*f(2,j2,i,n)
      t3 = s*f(3,j2,i,n)
      f(1,j2,i,n) = f(1,j1,i,n) - t1
      f(2,j2,i,n) = f(2,j1,i,n) - t2
      f(3,j2,i,n) = f(3,j1,i,n) - t3
      f(1,j1,i,n) = f(1,j1,i,n) + t1
      f(2,j1,i,n) = f(2,j1,i,n) + t2
      f(3,j1,i,n) = f(3,j1,i,n) + t3
   50 continue
   60 continue
   70 continue
   80 continue
c unscramble coefficients and normalize
      kmr = nxyz/nx
      nry = nxhyz/ny
      do 110 k = kypi, kypt
      do 100 j = 2, nxhh
      t1 = cmplx(aimag(sct(1+kmr*(j-1))),-real(sct(1+kmr*(j-1))))
      do 90 jj = 1, 3
      t = conjg(f(jj,nxh2-j,k,n))
      s = f(jj,j,k,n) + t
      t = (f(jj,j,k,n) - t)*t1
      f(jj,j,k,n) = ani*(s + t)
      f(jj,nxh2-j,k,n) = ani*conjg(s - t)
   90 continue
  100 continue
  110 continue
      do 130 k = kypi, kypt
      do 120 jj = 1, 3
      f(jj,1,k,n) = 
     1             2.0*ani*cmplx(real(f(jj,1,k,n)) + aimag(f(jj,1,k,n)),
     2                           real(f(jj,1,k,n)) - aimag(f(jj,1,k,n)))
      if (nxhh.gt.0) f(jj,nxhh+1,k,n) = 2.0*ani*conjg(f(jj,nxhh+1,k,n))
  120 continue
  130 continue
  140 continue
      return
c forward fourier transform
  150 do 290 n = 1, kzpp
c scramble coefficients
      kmr = nxyz/nx
      do 180 k = kypi, kypt
      do 170 j = 2, nxhh
      t1 = cmplx(aimag(sct(1+kmr*(j-1))),real(sct(1+kmr*(j-1))))
      do 160 jj = 1, 3
      t = conjg(f(jj,nxh2-j,k,n))
      s = f(jj,j,k,n) + t
      t = (f(jj,j,k,n) - t)*t1
      f(jj,j,k,n) = s + t
      f(jj,nxh2-j,k,n) = conjg(s - t)
  160 continue
  170 continue
  180 continue
      do 200 k = kypi, kypt
      do 190 jj = 1, 3
      f(jj,1,k,n) = cmplx(real(f(jj,1,k,n)) + aimag(f(jj,1,k,n)),
     1                    real(f(jj,1,k,n)) - aimag(f(jj,1,k,n)))
      if (nxhh.gt.0) f(jj,nxhh+1,k,n) = 2.0*conjg(f(jj,nxhh+1,k,n))
  190 continue
  200 continue
      nrx = nxhyz/nxh
c bit-reverse array elements in x
      do 220 j = 1, nxh
      j1 = (mixup(j) - 1)/nrx + 1
      if (j.ge.j1) go to 220
      do 210 i = kypi, kypt
      t1 = f(1,j1,i,n)
      t2 = f(2,j1,i,n)
      t3 = f(3,j1,i,n)
      f(1,j1,i,n) = f(1,j,i,n)
      f(2,j1,i,n) = f(2,j,i,n)
      f(3,j1,i,n) = f(3,j,i,n)
      f(1,j,i,n) = t1
      f(2,j,i,n) = t2
      f(3,j,i,n) = t3
  210 continue
  220 continue
c finally transform in x
      nrx = nxyz/nxh
      do 260 l = 1, indx1
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nxhh/ns
      kmr = km*nrx
      do 250 i = kypi, kypt
      do 240 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 230 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = conjg(sct(1+kmr*(j-1)))
      t1 = s*f(1,j2,i,n)
      t2 = s*f(2,j2,i,n)
      t3 = s*f(3,j2,i,n)
      f(1,j2,i,n) = f(1,j1,i,n) - t1
      f(2,j2,i,n) = f(2,j1,i,n) - t2
      f(3,j2,i,n) = f(3,j1,i,n) - t3
      f(1,j1,i,n) = f(1,j1,i,n) + t1
      f(2,j1,i,n) = f(2,j1,i,n) + t2
      f(3,j1,i,n) = f(3,j1,i,n) + t3
  230 continue
  240 continue
  250 continue
  260 continue
c swap complex components
      do 280 i = kypi, kypt
      do 270 j = 1, nxh
      at1 = real(f(3,j,i,n))
      f(3,j,i,n) = cmplx(aimag(f(2,j,i,n)),aimag(f(3,j,i,n)))
      at2 = real(f(2,j,i,n))
      f(2,j,i,n) = cmplx(at1,aimag(f(1,j,i,n)))
      f(1,j,i,n) = cmplx(real(f(1,j,i,n)),at2)
  270 continue
  280 continue
  290 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPFFT32R3XY(g,isign,mixup,sct,indx,indy,indz,kstrt,nvpy
     1,nvpz,kxypi,kxypp,nyv,kzpp,kxypd,kzpd,nxhyzd,nxyzhd)
c this subroutine performs the y part of 3 three dimensional real to
c complex fast fourier transforms and their inverses for a subset of
c x and z, using complex arithmetic,
c for data which is distributed in blocks, with 2D spatial decomposition
c for isign = (-1,1), input: all, output: g
c for isign = -1, approximate flop count: N*(5*log2(N) + 19/2)/nvp
c for isign = 1,  approximate flop count: N*(5*log2(N) + 15/2)/nvp
c where N = (nx/2)*ny*nz, and nvp = number of procs
c indx/indy/indz = exponent which determines length in x/y/z direction,
c where nx=2**indx, ny=2**indy, nz=2**indz
c if isign = -1, an inverse fourier transform is performed
c g(1:3,m,j,i) = sum(g(1:3,k,j,i)*exp(-sqrt(-1)*2pi*m*k/ny))
c if isign = 1, a forward fourier transform is performed
c g(1:3,m,j,i) = sum(g(1:3,k,j,i)*exp(sqrt(-1)*2pi*m*k/ny))
c kstrt = starting data block number
c nvpy/nvpz = number of real or virtual processors in y/z
c kxypi = initial x index used
c kxypp = number of x indices used
c nyv = first dimension of g
c kzpp = number of z indices used
c kxypd = second dimension of g
c kzpd = third dimension of g
c mixup = array of bit reversed addresses
c sct = sine/cosine table
c nxhyzd = maximum of (nx/2,ny,nz)
c nxyzhd = one half of maximum of (nx,ny,nz)
c final fourier coefficients are stored as follows:
c h(1:3,l,j,k) = mode jj-1,kk-1,l, where jj = j + kxyp*js,
c kk = k + kyzp*ks, and MPI rank idproc = js + nvpy*ks
c 1 <= jj <= nx/2, 1 <= kk <= ny, and 1 <= l <= nz, except for
c h(1:3,l,1,k) = mode nx/2,kk-1,l-1,
c where ny/2+2 <= kk <= ny, 1 <= l <= nz,
c the following are located on node js = 0 and ks = 0:
c h(1:3,l,1,1) = mode nx/2,0,l-1, where 2 <= l <= nz/2
c imag(h(1:3,1,1,1)) = real part of mode nx/2,0,0
c imag(h(1:3,nz/2+1,1,1)) = real part of mode nx/2,0,nz/2
c the following are located on node js = 0 and ks = nyh/kyzp:
c h(1:3,l,1,ny/2+1) = mode nx/2,ny/2,l-1, where nz/2+2 <= l <= nz, and
c imag(h(1:3,1,1,ny/2+1)) = real part of mode nx/2,ny/2,0
c imag(h(1:3,nz/2+1,1,ny/2+1)) = real part of mode nx/2,ny/2,nz/2
c using jpl storage convention, as described in:
c E. Huang, P. C. Liewer, V. K. Decyk, and R. D. Ferraro, "Concurrent
c Three-Dimensional Fast Fourier Transform Algorithms for Coarse-Grained
c Distributed Memory Parallel Computers," Caltech CRPC Report 217-50,
c December 1993.
c written by viktor k. decyk, ucla
c parallel, RISC optimized version
      implicit none
      integer isign, indx, indy, indz, kstrt, nvpy, nvpz, kxypi, kxypp
      integer nyv, kzpp, kxypd, kzpd, nxhyzd, nxyzhd
      integer mixup
      complex g, sct
      dimension g(3,nyv,kxypd,kzpd)
      dimension mixup(nxhyzd), sct(nxyzhd)
c local data
      integer indx1, ndx1yz, nx, nxh, ny, nyh, ny2, nz, nxyz, nxhyz
      integer j, k, l, i, n, ns, ns2, km, kmr, k1, k2, j1, j2, jj
      integer js, ks, nry, kxypt
      complex s, t1, t2, t3
      if (isign.eq.0) return
      indx1 = indx - 1
      ndx1yz = max0(indx1,indy,indz)
      nx = 2**indx
      nxh = nx/2
      ny = 2**indy
      nyh = max(1,ny/2)
      ny2 = ny + 2
      nz = 2**indz
      nxyz = max0(nx,ny,nz)
      nxhyz = 2**ndx1yz
      kxypt = kxypi + kxypp - 1
c js/ks = processor co-ordinates in x/z => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      if (kstrt.gt.(nvpy*nvpz)) return
      if (isign.gt.0) go to 110
c inverse fourier transform
      do 70 n = 1, kzpp
      nry = nxhyz/ny
c bit-reverse array elements in y
      do 20 k = 1, ny
      k1 = (mixup(k) - 1)/nry + 1
      if (k.ge.k1) go to 20
      do 10 i = kxypi, kxypt
      t1 = g(1,k1,i,n)
      t2 = g(2,k1,i,n)
      t3 = g(3,k1,i,n)
      g(1,k1,i,n) = g(1,k,i,n)
      g(2,k1,i,n) = g(2,k,i,n)
      g(3,k1,i,n) = g(3,k,i,n)
      g(1,k,i,n) = t1
      g(2,k,i,n) = t2
      g(3,k,i,n) = t3
   10 continue
   20 continue
c then transform in y
      nry = nxyz/ny
      do 60 l = 1, indy
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nyh/ns
      kmr = km*nry
      do 50 i = kxypi, kxypt
      do 40 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 30 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = sct(1+kmr*(j-1))
      t1 = s*g(1,j2,i,n)
      t2 = s*g(2,j2,i,n)
      t3 = s*g(3,j2,i,n)
      g(1,j2,i,n) = g(1,j1,i,n) - t1
      g(2,j2,i,n) = g(2,j1,i,n) - t2
      g(3,j2,i,n) = g(3,j1,i,n) - t3
      g(1,j1,i,n) = g(1,j1,i,n) + t1
      g(2,j1,i,n) = g(2,j1,i,n) + t2
      g(3,j1,i,n) = g(3,j1,i,n) + t3
   30 continue
   40 continue
   50 continue
   60 continue
   70 continue
c unscramble modes kx = 0, nx/2
      if (js.gt.0) return
      if (kxypi.eq.1) then
         do 100 n = 1, kzpp
         do 90 k = 2, nyh
         do 80 jj = 1, 3
         s = g(jj,ny2-k,1,n)
         g(jj,ny2-k,1,n) = 0.5*cmplx(aimag(g(jj,k,1,n) + s),
     1                               real(g(jj,k,1,n) - s))
         g(jj,k,1,n) = 0.5*cmplx(real(g(jj,k,1,n) + s),
     1                           aimag(g(jj,k,1,n) - s))
   80    continue
   90    continue
  100    continue
      endif
      return
c forward fourier transform
c scramble modes kx = 0, nx/2
  110 if (js.gt.0) go to 150
      if (kxypi.eq.1) then
         do 140 n = 1, kzpp
         do 130 k = 2, nyh
         do 120 jj = 1, 3
         s = cmplx(aimag(g(jj,ny2-k,1,n)),real(g(jj,ny2-k,1,n)))
         g(jj,ny2-k,1,n) = conjg(g(jj,k,1,n) - s)
         g(jj,k,1,n) = g(jj,k,1,n) + s
  120    continue
  130    continue
  140    continue
      endif
  150 do 220 n = 1, kzpp
      nry = nxhyz/ny
c bit-reverse array elements in y
      do 170 k = 1, ny
      k1 = (mixup(k) - 1)/nry + 1
      if (k.ge.k1) go to 170
      do 160 i = kxypi, kxypt
      t1 = g(1,k1,i,n)
      t2 = g(2,k1,i,n)
      t3 = g(3,k1,i,n)
      g(1,k1,i,n) = g(1,k,i,n)
      g(2,k1,i,n) = g(2,k,i,n)
      g(3,k1,i,n) = g(3,k,i,n)
      g(1,k,i,n) = t1
      g(2,k,i,n) = t2
      g(3,k,i,n) = t3
  160 continue
  170 continue
c then transform in y
      nry = nxyz/ny
      do 210 l = 1, indy
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nyh/ns
      kmr = km*nry
      do 200 i = kxypi, kxypt
      do 190 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 180 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = conjg(sct(1+kmr*(j-1)))
      t1 = s*g(1,j2,i,n)
      t2 = s*g(2,j2,i,n)
      t3 = s*g(3,j2,i,n)
      g(1,j2,i,n) = g(1,j1,i,n) - t1
      g(2,j2,i,n) = g(2,j1,i,n) - t2
      g(3,j2,i,n) = g(3,j1,i,n) - t3
      g(1,j1,i,n) = g(1,j1,i,n) + t1
      g(2,j1,i,n) = g(2,j1,i,n) + t2
      g(3,j1,i,n) = g(3,j1,i,n) + t3
  180 continue
  190 continue
  200 continue
  210 continue
  220 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPFFT32R3XZ(h,isign,mixup,sct,indx,indy,indz,kstrt,nvpy
     1,nvpz,kxypi,kxypp,nzv,kyzp,kxypd,kyzpd,nxhyzd,nxyzhd)
c this subroutine performs the z part of 3 three dimensional real to
c complex fast fourier transforms and their inverses for a subset of
c x and y, using complex arithmetic,
c for data which is distributed in blocks, with 2D spatial decomposition
c for isign = (-1,1), input: all, output: h
c for isign = -1, approximate flop count: N*(5*log2(N) + 19/2)/nvp
c for isign = 1,  approximate flop count: N*(5*log2(N) + 15/2)/nvp
c where N = (nx/2)*ny*nz, and nvp = number of procs
c indx/indy/indz = exponent which determines length in x/y/z direction,
c where nx=2**indx, ny=2**indy, nz=2**indz
c if isign = -1, an inverse fourier transform is performed
c h(1:3,l,n,m) = sum(h(1:3,i,j,k)*exp(-sqrt(-1)*2pi*l*i/nz))
c if isign = 1, a forward fourier transform is performed
c h(1:3,l,n,m) = sum(h(1:3,i,j,k)*exp(sqrt(-1)*2pi*ll*ii/nz))
c kstrt = starting data block number
c nvpy/nvpz = number of real or virtual processors in y/z
c kxypi = initial x index used
c kxypp = number of x indices used
c nzv = first dimension of h
c kyzpp = number of y indices used
c kxypd = second dimension of h
c kyzpd = third dimension of h
c mixup = array of bit reversed addresses
c sct = sine/cosine table
c nxhyzd = maximum of (nx/2,ny,nz)
c nxyzhd = one half of maximum of (nx,ny,nz)
c h(1:3,l,j,k) = mode jj-1,kk-1,l, where jj = j + kxyp*js,
c kk = k + kyzp*ks, and MPI rank idproc = js + nvpy*ks
c 1 <= jj <= nx/2, 1 <= kk <= ny, and 1 <= l <= nz, except for
c h(1:3,l,1,k) = mode nx/2,kk-1,l-1,
c where ny/2+2 <= kk <= ny, 1 <= l <= nz,
c the following are located on node js = 0 and ks = 0:
c h(1:3,l,1,1) = mode nx/2,0,l-1, where 2 <= l <= nz/2
c imag(h(1:3,1,1,1)) = real part of mode nx/2,0,0
c imag(h(1:3,nz/2+1,1,1)) = real part of mode nx/2,0,nz/2
c the following are located on node js = 0 and ks = nyh/kyzp:
c h(1:3,l,1,ny/2+1) = mode nx/2,ny/2,l-1, where nz/2+2 <= l <= nz, and
c imag(h(1:3,1,1,ny/2+1)) = real part of mode nx/2,ny/2,0
c imag(h(1:3,nz/2+1,1,ny/2+1)) = real part of mode nx/2,ny/2,nz/2
c using jpl storage convention, as described in:
c E. Huang, P. C. Liewer, V. K. Decyk, and R. D. Ferraro, "Concurrent
c Three-Dimensional Fast Fourier Transform Algorithms for Coarse-Grained
c Distributed Memory Parallel Computers," Caltech CRPC Report 217-50,
c December 1993.
c written by viktor k. decyk, ucla
c parallel, RISC optimized version
      implicit none
      integer isign, indx, indy, indz, kstrt, nvpy, nvpz, kxypi, kxypp
      integer nzv, kyzp, kxypd, kyzpd, nxhyzd, nxyzhd
      integer mixup
      complex h, sct
      dimension h(3,nzv,kxypd,kyzpd)
      dimension mixup(nxhyzd), sct(nxyzhd)
c local data
      integer indx1, ndx1yz, nx, nxh, ny, nyh, nz, nzh, nz2, nxyz, nxhyz
      integer j, k, l, i, n, ns, ns2, km, kmr, k1, k2, j1, j2, jj
      integer l1, js, ks, nrz, kxypt, kyzpp, kyzb
      complex s, t1, t2, t3
      indx1 = indx - 1
      ndx1yz = max0(indx1,indy,indz)
      nx = 2**indx
      nxh = nx/2
      ny = 2**indy
      nyh = max(1,ny/2)
      nz = 2**indz
      nzh = max(1,nz/2)
      nz2 = nz + 2
      nxyz = max0(nx,ny,nz)
      nxhyz = 2**ndx1yz
      kxypt = kxypi + kxypp - 1
c js/ks = processor co-ordinates in x/y => idproc = js + nvpy*ks
      ks = (kstrt - 1)/nvpy
      js = kstrt - nvpy*ks - 1
      kyzpp = min(kyzp,max(0,ny-kyzp*ks))
      if (kstrt.gt.(nvpy*nvpz)) return
      if (isign.gt.0) go to 120
c inverse fourier transform
      do 70 n = 1, kyzpp
      nrz = nxhyz/nz
c bit-reverse array elements in z
      do 20 l = 1, nz
      l1 = (mixup(l) - 1)/nrz + 1
      if (l.ge.l1) go to 20
      do 10 i = kxypi, kxypt
      t1 = h(1,l1,i,n)
      t2 = h(2,l1,i,n)
      t3 = h(3,l1,i,n)
      h(1,l1,i,n) = h(1,l,i,n)
      h(2,l1,i,n) = h(2,l,i,n)
      h(3,l1,i,n) = h(3,l,i,n)
      h(1,l,i,n) = t1
      h(2,l,i,n) = t2
      h(3,l,i,n) = t3
   10 continue
   20 continue
c finally transform in z
      nrz = nxyz/nz
      do 60 l = 1, indz
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nzh/ns
      kmr = km*nrz
      do 50 i = kxypi, kxypt
      do 40 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 30 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = sct(1+kmr*(j-1))
      t1 = s*h(1,j2,i,n)
      t2 = s*h(2,j2,i,n)
      t3 = s*h(3,j2,i,n)
      h(1,j2,i,n) = h(1,j1,i,n) - t1
      h(2,j2,i,n) = h(2,j1,i,n) - t2
      h(3,j2,i,n) = h(3,j1,i,n) - t3
      h(1,j1,i,n) = h(1,j1,i,n) + t1
      h(2,j1,i,n) = h(2,j1,i,n) + t2
      h(3,j1,i,n) = h(3,j1,i,n) + t3
   30 continue
   40 continue
   50 continue
   60 continue
   70 continue
c unscramble modes kx = 0, nx/2
      if (js.gt.0) return
      if (ks.eq.0) then
         if (kxypi.eq.1) then
            do 90 n = 2, nzh
            do 80 jj = 1, 3
            s = h(jj,nz2-n,1,1)
            h(jj,nz2-n,1,1) = 0.5*cmplx(aimag(h(jj,n,1,1) + s),
     1                                  real(h(jj,n,1,1) - s))
            h(jj,n,1,1) = 0.5*cmplx(real(h(jj,n,1,1) + s),
     1                              aimag(h(jj,n,1,1) - s))
   80       continue
   90       continue
         endif
      endif
      kyzb = nyh/kyzp
      if (ks.eq.kyzb) then
         k1 = nyh - kyzb*kyzp + 1
         if (kxypi.eq.1) then
            do 110 n = 2, nzh
            do 100 jj = 1, 3
            s = h(jj,nz2-n,1,k1)
            h(jj,nz2-n,1,k1) = 0.5*cmplx(aimag(h(jj,n,1,k1) + s),
     1                                   real(h(jj,n,1,k1) - s))

            h(jj,n,1,k1) = 0.5*cmplx(real(h(jj,n,1,k1) + s),
     1                               aimag(h(jj,n,1,k1) - s))
  100       continue
  110       continue
        endif
      endif
      return
c forward fourier transform
c scramble modes kx = 0, nx/2
  120 if (js.gt.0) go to 170
      if (ks.eq.0) then
         if (kxypi.eq.1) then
            do 140 n = 2, nzh
            do 130 jj = 1, 3
            s = cmplx(aimag(h(jj,nz2-n,1,1)),real(h(jj,nz2-n,1,1)))
            h(jj,nz2-n,1,1) = conjg(h(jj,n,1,1) - s)
            h(jj,n,1,1) = h(jj,n,1,1) + s
  130       continue
  140       continue
         endif
      endif
      kyzb = nyh/kyzp
      if (ks.eq.kyzb) then
         k1 = nyh - kyzb*kyzp + 1
         if (kxypi.eq.1) then
            do 160 n = 2, nzh
            do 150 jj = 1, 3
            s = cmplx(aimag(h(jj,nz2-n,1,k1)),real(h(jj,nz2-n,1,k1)))
            h(jj,nz2-n,1,k1) = conjg(h(jj,n,1,k1) - s)
            h(jj,n,1,k1) = h(jj,n,1,k1) + s
  150       continue
  160       continue
         endif
      endif
  170 do 240 n = 1, kyzpp
      nrz = nxhyz/nz
c bit-reverse array elements in z
      do 190 l = 1, nz
      l1 = (mixup(l) - 1)/nrz + 1
      if (l.ge.l1) go to 190
      do 180 i = kxypi, kxypt
      t1 = h(1,l1,i,n)
      t2 = h(2,l1,i,n)
      t3 = h(3,l1,i,n)
      h(1,l1,i,n) = h(1,l,i,n)
      h(2,l1,i,n) = h(2,l,i,n)
      h(3,l1,i,n) = h(3,l,i,n)
      h(1,l,i,n) = t1
      h(2,l,i,n) = t2
      h(3,l,i,n) = t3
  180 continue
  190 continue
c first transform in z
      nrz = nxyz/nz
      do 230 l = 1, indz
      ns = 2**(l - 1)
      ns2 = ns + ns
      km = nzh/ns
      kmr = km*nrz
      do 220 i = kxypi, kxypt
      do 210 k = 1, km
      k1 = ns2*(k - 1)
      k2 = k1 + ns
      do 200 j = 1, ns
      j1 = j + k1
      j2 = j + k2
      s = conjg(sct(1+kmr*(j-1)))
      t1 = s*h(1,j2,i,n)
      t2 = s*h(2,j2,i,n)
      t3 = s*h(3,j2,i,n)
      h(1,j2,i,n) = h(1,j1,i,n) - t1
      h(2,j2,i,n) = h(2,j1,i,n) - t2
      h(3,j2,i,n) = h(3,j1,i,n) - t3
      h(1,j1,i,n) = h(1,j1,i,n) + t1
      h(2,j1,i,n) = h(2,j1,i,n) + t2
      h(3,j1,i,n) = h(3,j1,i,n) + t3
  200 continue
  210 continue
  220 continue
  230 continue
  240 continue
      return
      end
c-----------------------------------------------------------------------
      subroutine PPGSPOST32L(part,q,npp,noff,qm,idimp,npmax,nxv,nypmx,  
     1nxyzp,idds)
c for 3d code, this subroutine calculates particle charge density
c using first-order linear interpolation, and distributed data
c with 2D spatial decomposition
c scalar version using guard cells, integer conversion precalculation,
c and 1d addressing, for distributed data
c cases 9-10 in v.k.decyk et al, computers in physics 10, 290 (1996).
c 33 flops/particle, 11 loads, 8 stores
c input: all, output: q
c charge density is approximated by values at the nearest grid points
c q(n,m,l)=qm*(1.-dx)*(1.-dy)*(1.-dz)
c q(n+1,m,l)=qm*dx*(1.-dy)*(1.-dz)
c q(n,m+1,l)=qm*(1.-dx)*dy*(1.-dz)
c q(n+1,m+1,l)=qm*dx*dy*(1.-dz)
c q(n,m,l+1)=qm*(1.-dx)*(1.-dy)*dz
c q(n+1,m,l+1)=qm*dx*(1.-dy)*dz
c q(n,m+1,l+1)=qm*(1.-dx)*dy*dz
c q(n+1,m+1,l+1)=qm*dx*dy*dz
c where n,m,l = leftmost grid points and dx = x-n, dy = y-m, dz = z-l
c part(1,n) = position x of particle n in partition
c part(2,n) = position y of particle n in partition
c part(3,n) = position z of particle n in partition
c q(j,k,l) = charge density at grid point (j,kk,ll),
c where kk = k + noff(1) - 1, and ll = l + noff(2) - 1
c npp = number of particles in partition
c noff(1) = lowermost global gridpoint in y in particle partition
c noff(2) = backmost global gridpoint in z in particle partition
c qm = charge on particle, in units of e
c idimp = size of phase space = 6
c npmax = maximum number of particles in each partition
c nxv = first virtual dimension of charge array, must be >= nx+1
c nypmx = maximum size of particle partition in y, including guard cells
c nxyzp = dimension of charge array, must be >= nxv*nypmx*nzpmx
c idds = dimensionality of domain decomposition
      implicit none
      integer npp, idimp, npmax, nxv, nypmx, nxyzp, idds
      real qm
      integer noff
      real part, q
      dimension noff(idds)
      dimension part(idimp,npmax), q(nxyzp)
c local data
      integer j, nxvy, mnoff, lnoff, nnn, mmm, lll, nn, mm, ll, mp, lp
      real dxn, dyn, dzn, dxp, dyp, dzp, amx, amy, amz, dx1, dx2, dx3
      nxvy = nxv*nypmx
      if (npp.lt.1) return
      mnoff = noff(1)
      lnoff = noff(2)
c begin first particle
      nnn = part(1,1)
      mmm = part(2,1)
      lll = part(3,1)
      dxn = part(1,1) - real(nnn)
      dyn = part(2,1) - real(mmm)
      dzn = part(3,1) - real(lll)
      mmm = mmm - mnoff
      lll = lll - lnoff
c find interpolation weights
      do 10 j = 2, npp
      nn = nnn + 1
      mm = nxv*mmm + nxvy*lll
      nnn = part(1,j)
      mmm = part(2,j)
      lll = part(3,j)
      dxp = qm*dxn
      dyp = dyn
      dzp = dzn
      dxn = part(1,j) - real(nnn)
      dyn = part(2,j) - real(mmm)
      dzn = part(3,j) - real(lll)
      amx = qm - dxp
      amy = 1.0 - dyp
      mm = mm + nn
      dx1 = dxp*dyp
      dyp = amx*dyp
      mp = mm + nxv
      amx = amx*amy
      amz = 1.0 - dzp
      ll = mm + nxvy
      amy = dxp*amy
      lp = mp + nxvy
      mmm = mmm - mnoff
      lll = lll - lnoff
c deposit charge
      dxp = q(mm) + amx*amz
      dx2 = q(mm+1) + amy*amz
      dx3 = q(mp) + dyp*amz
      amz = q(mp+1) + dx1*amz
      amx = q(ll) + amx*dzp
      amy = q(ll+1) + amy*dzp
      dyp = q(lp) + dyp*dzp
      dzp = q(lp+1) + dx1*dzp
      q(mm) = dxp
      q(mm+1) = dx2
      q(mp) = dx3
      q(mp+1) = amz
      q(ll) = amx
      q(ll+1) = amy
      q(lp) = dyp
      q(lp+1) = dzp
   10 continue
c deposit charge for last particle
      nn = nnn + 1
      mm = nxv*mmm + nxvy*lll
      dxp = qm*dxn
      amx = qm - dxp
      amy = 1.0 - dyn
      mm = mm + nn
      dx1 = dxp*dyn
      dyp = amx*dyn
      mp = mm + nxv
      amx = amx*amy
      amz = 1.0 - dzn
      ll = mm + nxvy
      amy = dxp*amy
      lp = mp + nxvy
c deposit charge
      q(mm) = q(mm) + amx*amz
      q(mm+1) = q(mm+1) + amy*amz
      q(mp) = q(mp) + dyp*amz
      q(mp+1) = q(mp+1) + dx1*amz
      q(ll) = q(ll) + amx*dzn
      q(ll+1) = q(ll+1) + amy*dzn
      q(lp) = q(lp) + dyp*dzn
      q(lp+1) = q(lp+1) + dx1*dzn
      return
      end
c-----------------------------------------------------------------------
      subroutine PPGSPUSH32L(part,fxyz,edges,npp,noff,ihole,qbm,dt,ek,nx
     1,ny,nz,idimp,npmax,nxv,nypmx,nxyzp,idps,idds,ntmax,ipbc)
c for 3d code, this subroutine updates particle co-ordinates and
c velocities using leap-frog scheme in time and first-order linear
c interpolation in space,, with various boundary conditions.
c also determines list of particles which are leaving this processor
c for distributed data, with 2D spatial decomposition
c scalar version using guard cells, integer conversion precalculation,
c and 1d addressing
c 90 flops/particle, 30 loads, 6 stores
c input: all except ihole, output: part, ihole, ek
c equations used are:
c vx(t+dt/2) = vx(t-dt/2) + (q/m)*fx(x(t),y(t),z(t))*dt,
c vy(t+dt/2) = vy(t-dt/2) + (q/m)*fy(x(t),y(t),z(t))*dt,
c vz(t+dt/2) = vz(t-dt/2) + (q/m)*fz(x(t),y(t),z(t))*dt,
c where q/m is charge/mass, and
c x(t+dt) = x(t) + vx(t+dt/2)*dt, y(t+dt) = y(t) + vy(t+dt/2)*dt,
c z(t+dt) = z(t) + vz(t+dt/2)*dt
c fx(x(t),y(t),z(t)), fy(x(t),y(t),z(t)), and fz(x(t),y(t),z(t))
c are approximated by interpolation from the nearest grid points:
c fx(x,y,z) = (1-dz)*((1-dy)*((1-dx)*fx(n,m,l)+dx*fx(n+1,m,l))
c                + dy*((1-dx)*fx(n,m+1,l) + dx*fx(n+1,m+1,l)))
c           + dz*((1-dy)*((1-dx)*fx(n,m,l+1)+dx*fx(n+1,m,l+1))
c                + dy*((1-dx)*fx(n,m+1,l+1) + dx*fx(n+1,m+1,l+1)))
c fy(x,y,z) = (1-dz)*((1-dy)*((1-dx)*fy(n,m,l)+dx*fy(n+1,m,l))
c                + dy*((1-dx)*fy(n,m+1,l) + dx*fy(n+1,m+1,l)))
c           + dz*((1-dy)*((1-dx)*fy(n,m,l+1)+dx*fy(n+1,m,l+1))
c                + dy*((1-dx)*fy(n,m+1,l+1) + dx*fy(n+1,m+1,l+1)))
c fz(x,y,z) = (1-dz)*((1-dy)*((1-dx)*fz(n,m,l)+dx*fz(n+1,m,l))
c                + dy*((1-dx)*fz(n,m+1,l) + dx*fz(n+1,m+1,l)))
c           + dz*((1-dy)*((1-dx)*fz(n,m,l+1)+dx*fz(n+1,m,l+1))
c                + dy*((1-dx)*fz(n,m+1,l+1) + dx*fz(n+1,m+1,l+1)))
c where n,m,l = leftmost grid points and dx = x-n, dy = y-m, dz = z-l
c part(1,n) = position x of particle n in partition
c part(2,n) = position y of particle n in partition
c part(3,n) = position z of particle n in partition
c part(4,n) = velocity vx of particle n in partition
c part(5,n) = velocity vy of particle n in partition
c part(6,n) = velocity vz of particle n in partition
c fxyz(1,j,k,l) = x component of force/charge at grid (j,kk,ll)
c fxyz(2,j,k,l) = y component of force/charge at grid (j,kk,ll)
c fxyz(3,j,k,l) = z component of force/charge at grid (j,kk,ll)
c in other words, fxyz are the convolutions of the electric field
c over the particle shape,
c where kk = k + noff(1) - 1, and ll = l + noff(2) - 1
c edges(1:2) = lower/upper boundary in y of particle partition
c edges(3:4) = back/front boundary in z of particle partition
c npp = number of particles in partition
c noff(1) = lowermost global gridpoint in y in particle partition
c noff(2) = backmost global gridpoint in z in particle partition
c ihole(:,2) = location of holes left in y/z in particle arrays
c ihole(1,:) = ih, number of holes left in y/z (error, if negative)
c qbm = particle charge/mass ratio
c dt = time interval between successive calculations
c kinetic energy/mass at time t is also calculated, using
c ek = .125*sum((vx(t+dt/2)+vx(t-dt/2))**2+(vy(t+dt/2)+vy(t-dt/2))**2+
c (vz(t+dt/2)+vz(t-dt/2))**2)
c nx/ny/nz = system length in x/y/z direction
c idimp = size of phase space = 6
c npmax = maximum number of particles in each partition
c nxv = first virtual dimension of field array, must be >= nx+1
c nypmx = maximum size of particle partition in y, including guard cells
c nxyzp = dimension of field array, must be >= nxv*nypmx*nzpmx
c idps = number of particle partition boundaries = 4
c idds = dimensionality of domain decomposition
c ntmax = size of hole array for particles leaving processors
c ipbc = particle boundary condition = (0,1,2,3) =
c (none,3d periodic,3d reflecting,mixed 2d reflecting/1d periodic)
      implicit none
      integer npp, nx, ny, nz, idimp, npmax, nxv, nypmx, nxyzp, idps
      integer idds, ntmax, ipbc
      real qbm, dt, ek
      real part, fxyz, edges
      integer noff, ihole
      dimension part(idimp,npmax), fxyz(3,nxyzp)
      dimension edges(idps)
      dimension noff(idds), ihole(ntmax+1,2)
c local data
      integer j, nxvy, mnoff, lnoff, nnn, mmm, lll, nop, nop1
      integer nn, mm, ll, mp, lp, ih1, ih2, nh
      real qtm, edgelx, edgely, edgelz, edgerx, edgery, edgerz
      real dxn, dyn, dzn, dxp, dyp, dzp, amx, amy, amz, dx1, dx, dy, dz
      double precision sum1
      qtm = qbm*dt
      sum1 = 0.0d0
      nxvy = nxv*nypmx
c set boundary values
      edgelx = 0.0
      edgely = 0.0
      edgelz = 0.0
      edgerx = real(nx)
      edgery = real(ny)
      edgerz = real(nz)
      if (ipbc.eq.2) then
         edgelx = 1.0
         edgely = 1.0
         edgelz = 1.0
         edgerx = real(nx-1)
         edgery = real(ny-1)
         edgerz = real(nz-1)
      else if (ipbc.eq.3) then
         edgelx = 1.0
         edgely = 1.0
         edgerx = real(nx-1)
         edgery = real(ny-1)
      endif
      if (npp.lt.1) return
      mnoff = noff(1)
      lnoff = noff(2)
      ih1 = 0
      ih2 = 0
      nh = 0
c begin first particle
      nnn = part(1,1)
      mmm = part(2,1)
      lll = part(3,1)
      dxn = part(1,1) - real(nnn)
      dyn = part(2,1) - real(mmm)
      dzn = part(3,1) - real(lll)
      mmm = mmm - mnoff
      lll = lll - lnoff
      nop1 = npp - 1
      do 10 j = 1, nop1
c find interpolation weights
      nn = nnn + 1
      mm = nxv*mmm + nxvy*lll
      nnn = part(1,j+1)
      mmm = part(2,j+1)
      lll = part(3,j+1)
      dxp = dxn
      dyp = dyn
      dzp = dzn
      dxn = part(1,j+1) - real(nnn)
      dyn = part(2,j+1) - real(mmm)
      dzn = part(3,j+1) - real(lll)
      amx = 1.0 - dxp
      amy = 1.0 - dyp
      mm = mm + nn
      dx1 = dxp*dyp
      dyp = amx*dyp
      mp = mm + nxv
      amx = amx*amy
      amz = 1.0 - dzp
      ll = mm + nxvy
      amy = dxp*amy
      lp = mp + nxvy
      mmm = mmm - mnoff
      lll = lll - lnoff
c find acceleration
      dx = amz*(amx*fxyz(1,mm) + amy*fxyz(1,mm+1) + dyp*fxyz(1,mp)
     1        + dx1*fxyz(1,mp+1))
     2   + dzp*(amx*fxyz(1,ll) + amy*fxyz(1,ll+1) + dyp*fxyz(1,lp)
     3        + dx1*fxyz(1,lp+1))
      dy = amz*(amx*fxyz(2,mm) + amy*fxyz(2,mm+1) + dyp*fxyz(2,mp)
     1        + dx1*fxyz(2,mp+1))
     2   + dzp*(amx*fxyz(2,ll) + amy*fxyz(2,ll+1) + dyp*fxyz(2,lp)
     3        + dx1*fxyz(2,lp+1))
      dz = amz*(amx*fxyz(3,mm) + amy*fxyz(3,mm+1) + dyp*fxyz(3,mp)
     1        + dx1*fxyz(3,mp+1))
     2   + dzp*(amx*fxyz(3,ll) + amy*fxyz(3,ll+1) + dyp*fxyz(3,lp)
     3        + dx1*fxyz(3,lp+1))
c new velocity
      dx = part(4,j) + qtm*dx
      dy = part(5,j) + qtm*dy
      dz = part(6,j) + qtm*dz
c average kinetic energy
      sum1 = sum1 + (dx + part(4,j))**2 + (dy + part(5,j))**2
     1            + (dz + part(6,j))**2
      part(4,j) = dx
      part(5,j) = dy
      part(6,j) = dz
c new position
      dx = part(1,j) + dx*dt
      dy = part(2,j) + dy*dt
      dz = part(3,j) + dz*dt
c periodic boundary conditions in x
      if (ipbc.eq.1) then
         if (dx.lt.edgelx) dx = dx + edgerx
         if (dx.ge.edgerx) dx = dx - edgerx
c reflecting boundary conditions
      else if (ipbc.eq.2) then
         if ((dx.lt.edgelx).or.(dx.ge.edgerx)) then
            dx = part(1,j)
            part(4,j) = -part(4,j)
         endif
         if ((dy.lt.edgely).or.(dy.ge.edgery)) then
            dy = part(2,j)
            part(5,j) = -part(5,j)
         endif
         if ((dz.lt.edgelz).or.(dz.ge.edgerz)) then
            dz = part(3,j)
            part(6,j) = -part(6,j)
         endif
c mixed reflecting/periodic boundary conditions
      else if (ipbc.eq.3) then
         if ((dx.lt.edgelx).or.(dx.ge.edgerx)) then
            dx = part(1,j)
            part(4,j) = -part(4,j)
         endif
         if ((dy.lt.edgely).or.(dy.ge.edgery)) then
            dy = part(2,j)
            part(5,j) = -part(5,j)
         endif
      endif
c find particles out of bounds
c check particles leaving in y direction or y and z
      if ((dy.lt.edges(1)).or.(dy.ge.edges(2))) then
         ih1 = ih1 + 1
         if (ih1.le.ntmax) then
            ihole(ih1+1,1) = j
         else
            nh = 1
         endif
c check particles leaving in z direction only
      else if ((dz.lt.edges(3)).or.(dz.ge.edges(4))) then
         ih2 = ih2 + 1
         if (ih2.le.ntmax) then
            ihole(ih2+1,2) = j
         else
            nh = 1
         endif
      endif
c set new position
      part(1,j) = dx
      part(2,j) = dy
      part(3,j) = dz
   10 continue
      nop = npp
c push last particle
      nn = nnn + 1
      mm = nxv*mmm + nxvy*lll
      amx = 1.0 - dxn
      amy = 1.0 - dyn
      mm = mm + nn
      dx1 = dxn*dyn
      dyp = amx*dyn
      mp = mm + nxv
      amx = amx*amy
      amz = 1.0 - dzn
      ll = mm + nxvy
      amy = dxn*amy
      lp = mp + nxvy
c find acceleration
      dx = amz*(amx*fxyz(1,mm) + amy*fxyz(1,mm+1) + dyp*fxyz(1,mp)
     1        + dx1*fxyz(1,mp+1))
     2   + dzn*(amx*fxyz(1,ll) + amy*fxyz(1,ll+1) + dyp*fxyz(1,lp)
     3        + dx1*fxyz(1,lp+1))
      dy = amz*(amx*fxyz(2,mm) + amy*fxyz(2,mm+1) + dyp*fxyz(2,mp)
     1        + dx1*fxyz(2,mp+1))
     2   + dzn*(amx*fxyz(2,ll) + amy*fxyz(2,ll+1) + dyp*fxyz(2,lp)
     3        + dx1*fxyz(2,lp+1))
      dz = amz*(amx*fxyz(3,mm) + amy*fxyz(3,mm+1) + dyp*fxyz(3,mp)
     1        + dx1*fxyz(3,mp+1))
     2   + dzn*(amx*fxyz(3,ll) + amy*fxyz(3,ll+1) + dyp*fxyz(3,lp)
     3        + dx1*fxyz(3,lp+1))
c new velocity
      dx = part(4,nop) + qtm*dx
      dy = part(5,nop) + qtm*dy
      dz = part(6,nop) + qtm*dz
c average kinetic energy
      sum1 = sum1 + (dx + part(4,nop))**2 + (dy + part(5,nop))**2 
     1            + (dz+ part(6,nop))**2
      part(4,nop) = dx
      part(5,nop) = dy
      part(6,nop) = dz
c new position
      dx = part(1,nop) + dx*dt
      dy = part(2,nop) + dy*dt
      dz = part(3,nop) + dz*dt
c periodic boundary conditions in x
      if (ipbc.eq.1) then
         if (dx.lt.edgelx) dx = dx + edgerx
         if (dx.ge.edgerx) dx = dx - edgerx
c reflecting boundary conditions
      else if (ipbc.eq.2) then
         if ((dx.lt.edgelx).or.(dx.ge.edgerx)) then
            dx = part(1,nop)
            part(4,nop) = -part(4,nop)
         endif
         if ((dy.lt.edgely).or.(dy.ge.edgery)) then
            dy = part(2,nop)
            part(5,nop) = -part(5,nop)
         endif
         if ((dz.lt.edgelz).or.(dz.ge.edgerz)) then
            dz = part(3,nop)
            part(6,nop) = -part(6,nop)
         endif
c mixed reflecting/periodic boundary conditions
      else if (ipbc.eq.3) then
         if ((dx.lt.edgelx).or.(dx.ge.edgerx)) then
            dx = part(1,nop)
            part(4,nop) = -part(4,nop)
         endif
         if ((dy.lt.edgely).or.(dy.ge.edgery)) then
            dy = part(2,nop)
            part(5,nop) = -part(5,nop)
         endif
      endif
c find particles out of bounds
c check particles leaving in y direction or y and z
      if ((dy.lt.edges(1)).or.(dy.ge.edges(2))) then
         ih1 = ih1 + 1
         if (ih1.le.ntmax) then
            ihole(ih1+1,1) = j
         else
            nh = 1
         endif
c check particles leaving in z direction only
      else if ((dz.lt.edges(3)).or.(dz.ge.edges(4))) then
         ih2 = ih2 + 1
         if (ih2.le.ntmax) then
            ihole(ih2+1,2) = nop
         else
            nh = 1
         endif
      endif
c set new position
      part(1,nop) = dx
      part(2,nop) = dy
      part(3,nop) = dz
c set end of file flag
      if (nh.gt.0) ih1 = -max(ih1,ih2)
      ihole(1,1) = ih1
      ihole(1,2) = ih2
c normalize kinetic energy
      ek = ek + 0.125*sum1
      return
      end
c-----------------------------------------------------------------------
      function ranorm()
c this program calculates a random number y from a gaussian distribution
c with zero mean and unit variance, according to the method of
c mueller and box:
c    y(k) = (-2*ln(x(k)))**1/2*sin(2*pi*x(k+1))
c    y(k+1) = (-2*ln(x(k)))**1/2*cos(2*pi*x(k+1)),
c where x is a random number uniformly distributed on (0,1).
c written for the ibm by viktor k. decyk, ucla
      implicit none
      integer iflg,isc,i1,r1,r2,r4,r5
      double precision ranorm,h1l,h1u,h2l,r0,r3,asc,bsc,temp
      save iflg,r1,r2,r4,r5,h1l,h1u,h2l,r0
      data r1,r2,r4,r5 /885098780,1824280461,1396483093,55318673/
      data h1l,h1u,h2l /65531.0d0,32767.0d0,65525.0d0/
      data iflg,r0 /0,0.0d0/
      if (iflg.eq.0) go to 10
      ranorm = r0
      r0 = 0.0d0
      iflg = 0
      return
   10 isc = 65536
      asc = dble(isc)
      bsc = asc*asc
      i1 = r1 - (r1/isc)*isc
      r3 = h1l*dble(r1) + asc*h1u*dble(i1)
      i1 = r3/bsc
      r3 = r3 - dble(i1)*bsc
      bsc = 0.5d0*bsc
      i1 = r2/isc
      isc = r2 - i1*isc
      r0 = h1l*dble(r2) + asc*h1u*dble(isc)
      asc = 1.0d0/bsc
      isc = r0*asc
      r2 = r0 - dble(isc)*bsc
      r3 = r3 + (dble(isc) + 2.0d0*h1u*dble(i1))
      isc = r3*asc
      r1 = r3 - dble(isc)*bsc
      temp = dsqrt(-2.0d0*dlog((dble(r1) + dble(r2)*asc)*asc))
      isc = 65536
      asc = dble(isc)
      bsc = asc*asc
      i1 = r4 - (r4/isc)*isc
      r3 = h2l*dble(r4) + asc*h1u*dble(i1)
      i1 = r3/bsc
      r3 = r3 - dble(i1)*bsc
      bsc = 0.5d0*bsc
      i1 = r5/isc
      isc = r5 - i1*isc
      r0 = h2l*dble(r5) + asc*h1u*dble(isc)
      asc = 1.0d0/bsc
      isc = r0*asc
      r5 = r0 - dble(isc)*bsc
      r3 = r3 + (dble(isc) + 2.0d0*h1u*dble(i1))
      isc = r3*asc
      r4 = r3 - dble(isc)*bsc
      r0 = 6.28318530717959d0*((dble(r4) + dble(r5)*asc)*asc)
      ranorm = temp*dsin(r0)
      r0 = temp*dcos(r0)
      iflg = 1
      return
      end
c-----------------------------------------------------------------------
      function randum()
c this is a version of the random number generator dprandom due to
c c. bingham and the yale computer center, producing numbers
c in the interval (0,1).  written for the sun by viktor k. decyk, ucla
      implicit none
      integer isc,i1,r1,r2
      double precision randum,h1l,h1u,r0,r3,asc,bsc
      save r1,r2,h1l,h1u
      data r1,r2 /1271199957,1013501921/
      data h1l,h1u /65533.0d0,32767.0d0/
      isc = 65536
      asc = dble(isc)
      bsc = asc*asc
      i1 = r1 - (r1/isc)*isc
      r3 = h1l*dble(r1) + asc*h1u*dble(i1)
      i1 = r3/bsc
      r3 = r3 - dble(i1)*bsc
      bsc = 0.5d0*bsc
      i1 = r2/isc
      isc = r2 - i1*isc
      r0 = h1l*dble(r2) + asc*h1u*dble(isc)
      asc = 1.0d0/bsc
      isc = r0*asc
      r2 = r0 - dble(isc)*bsc
      r3 = r3 + (dble(isc) + 2.0d0*h1u*dble(i1))
      isc = r3*asc
      r1 = r3 - dble(isc)*bsc
      randum = (dble(r1) + dble(r2)*asc)*asc
      return
      end
