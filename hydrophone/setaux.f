c     ============================================
      subroutine setaux(mbc,mx,my,xlower,ylower,dx,dy,
     &                  maux,aux)
c     ============================================
c
c     # set auxiliary arrays 
c     # dummy routine when no auxiliary arrays
c
c     
      ! Load implicit and auxiliary variables
      implicit double precision (a-h,o-z)
      dimension aux(maux,1-mbc:mx+mbc,1-mbc:my+mbc)
      
      ! Load common blocks (EOS parameters and densities)    
      common /param/ gammagas, gammaplas, gammawat
      common /param/ pinfgas,pinfplas,pinfwat
      common /param/ omegas,omeplas,omewat
      common /param/ rhog,rhop,rhow
      
      ! Aux arrays establish values for the two free parameters in polystyrene EOS
      ! Polystyrene EOS based on Van der Waals approximation in Spender and Gilmore paper
      ! aux(1,:,:) plays the role of gamma, aux(2,:,:) plays the role of pinf
      ! and aux(3,:,:) could be another parameter (set to zero here)
      
      ! Loop over all cells
      do i=1-mbc,mx + mbc
        xcell = xlower + (i-0.5d0)*dx
        do j=1-mbc,my + mbc
            ycell = ylower + (j-0.5d0)*dy
            ! Water box immersed in air
            if ((abs(xcell+0.0).le.0.0085).and. (ycell.le.0.0085)) then
                aux(1,i,j) = gammawat
                aux(2,i,j) = pinfwat
                aux(3,i,j) = omewat
                ! Add hydrophone
                if ((xcell > -0.0055).and.(ycell.le.0.0015)) then
                    aux(1,i,j) = gammaplas
                    aux(2,i,j) = pinfplas
                    aux(3,i,j) = omeplas
                end if
            else 
                ! Air parameters
                aux(1,i,j) = gammagas
                aux(2,i,j) = pinfgas
                aux(3,i,j) = omegas
            end if
          
        end do
      end do
c
      return
      end


