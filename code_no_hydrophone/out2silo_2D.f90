! Writes solution file in Silo format
! nx:=number of grid points in x
! ny:=number of grid points in y
! counter:=number added at the end of the filename
SUBROUTINE out_2_silo(qi,nx,ny,xlower,ylower,dx,dy,figno,counter)

  include 'silo.inc'
  
  ! Declare variables required for SILO output
  CHARACTER(len=23)    :: filename, meshname,varname
  INTEGER              :: nx,ny,nz,counter,figno
  double precision     :: xlower,ylower,dx,dy
  double precision     :: xx(1:nx),yy(1:ny)
  double precision     :: qi(1:nx,1:ny)
  INTEGER              :: dims(2),sid,GridOpts,stat,rcode

  ! Silo filename info
  write(filename,'(a5,i4.4,a5)') 'forts', counter,'.silo'
  rcode=dbcreate(filename,len(trim(filename)),DB_CLOBBER, DB_LOCAL, 'file info',len('file info'), DB_PDB,sid);
  
  ! Load mesh
  do i=1,nx
      xx(i) = xlower + (real(i-1))*dx;
  end do
  do i=1,ny
      yy(i) = ylower + (real(i-1))*dy;
  end do
  dims(1) = nx;
  dims(2) = ny;
  
  ! Create mesh
  rcode=dbmkoptlist(1,GridOpts)
  meshname='mesh'
  varname='pressure'

  ! Output SILO commands
  rcode=dbputqm(sid, trim(meshname), len(trim(meshname)), 'x', 1, 'y', 1, 0, 0, xx, yy, 0, dims, 2, &
      &            DB_DOUBLE, DB_COLLINEAR,GridOpts,stat)      
  rcode=dbputqv1(sid,trim(varname),len(trim(varname)),trim(meshname), len(trim(meshname)),qi(:,:),dims,2,&
        & DB_F77NULL,0,DB_DOUBLE,DB_NODECENT,GridOpts,stat)
  rcode=dbclose(sid)

  RETURN;
END