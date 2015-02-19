! Returns phi function to obtain zero of exact Euler equations with Tammann EOS
! phi_m corrspond to phi obtain by rarefaction waves
! phi_p correspond to phi to obtain shockwaves
SUBROUTINE phi_exact(gammal,gammar,pr,pl,rho_r,rho_l,ul,ur,pinfl,pinfr,p,phi,& 
                     phi_prime,rhos_l,rhos_r,ustar)

    IMPLICIT NONE
    ! Declare left and right parameters for Euler eqs. priitive variables
    ! and for Tammann EOS parameters
    REAL (kind=8) :: gammal,gammar,pr,pl,rho_r,rho_l,ul,ur
    REAL (kind=8) :: pinfl,pinfr,p,phi,phi_prime,rhos_l,rhos_r,ustar
    
    ! Declares left and right quantities that will be required in the computation
    REAL (kind=8) :: cl, cr, gl1, gr1, bl, br
    REAL (kind=8) :: phil_m, phil_p, phir_m, phir_p
    REAL (kind=8) :: lm_prime, rm_prime, lp_prime, rp_prime
    
    REAL (kind=8) :: al, ar, betal, betar, pbl, pbr, pbsl, pbsr
    
    ! Bar pressure (See cited paper (Ivings or delRazo))
    pbl = pl + pinfl
    pbr = pr + pinfr
    ! Star bar pressure
    pbsl = p + pinfl
    pbsr = p + pinfr
           
    ! Useful parameters
    gl1 = gammal - 1.0
    gr1 = gammar - 1.0
    bl = (gammal + 1.0)/(gammal - 1.0)
    br = (gammar + 1.0)/(gammar - 1.0)
    betal = pbl/bl
    betar = pbr/br
    al = 2.0/((gammal + 1.0)*rho_l)
    ar = 2.0/((gammar + 1.0)*rho_r)
    cl =  dsqrt(gammal*(pl + pinfl)/rho_l)
    cr =  dsqrt(gammar*(pr + pinfr)/rho_r)
    ! Calculate the rarefaction phi's and its derivatives
    phil_m = ul + 2*cl/gl1*(1 - (pbsl/pbl)**(gl1/(2.0*gammal)))
    phir_m = ur - 2*cr/gr1*(1 - (pbsr/pbr)**(gr1/(2.0*gammar)))
    ! Calculates its derivatives
    lm_prime = -cl/(pbl*gammal)*(pbsl/pbl)**((-gammal - 1.0)/(2*gammal)) 
    rm_prime = cr/(pbr*gammar)*(pbsr/pbr)**((-gammar - 1.0)/(2*gammar))
        
    ! Use shockwave phi's (from Ivings or DelRazo's paper) (can be used for Tamman too)
    phil_p = ul - (p - pl)*dsqrt(al/(pbsl + betal))
    phir_p = ur + (p - pr)*dsqrt(ar/(pbsr + betar))
    lp_prime = - dsqrt(al/(pbsl + betal)) 
    lp_prime = lp_prime + (pbsl - pbl)*dsqrt(al/(pbsl + betal)**3)/2.0
    rp_prime = + dsqrt(ar/(pbsr + betar)) 
    rp_prime = rp_prime - (pbsr - pbr)*dsqrt(ar/(pbsr + betar)**3)/2.0
    
    ! Assign value to phi_r - phi_l  and the primed depending on the case
    ! Rarefaction - Rarefaction
    if (p .le. pl .and. p .le. pr)  then
        phi = phir_m - phil_m
        phi_prime = rm_prime - lm_prime 
        ustar = 0.5*(phir_m + phil_m)
        rhos_l = rho_l*(pbsl/pbl)**(1.0/gammal)
        rhos_r = rho_r*(pbsr/pbr)**(1.0/gammar)
!         print*, 'Rarefaction-Rarefaction'
    ! Shockwave - Rarefaction
    else if (pl .le. p  .and. p .le. pr) then
        phi = phir_m - phil_p
        phi_prime = rm_prime - lp_prime
        ustar = 0.5*(phir_m + phil_p)
        rhos_l = rho_l*(pbsl/pbl + 1.0/bl)/(pbsl/(pbl*bl) + 1.0)
        rhos_r = rho_r*(pbsr/pbr)**(1.0/gammar)
!         print*, 'Shockwave-Rarefaction'
    ! Rarefaction - Shockwave    
    else if (pr .le. p .and. p .le. pl) then
        phi = phir_p - phil_m
        phi_prime = rp_prime - lm_prime
        ustar = 0.5*(phir_p + phil_m)
        rhos_l = rho_l*(pbsl/pbl)**(1.0/gammal)
        rhos_r = rho_r*(pbsr/pbr + 1.0/br)/(pbsr/(pbr*br) + 1.0)
!         print*, 'Rarefaction-Shockwave'
    ! Shockwave - Shockwave    
    else if (p .ge. pr .and. p .ge. pl) then
        phi = phir_p - phil_p
        phi_prime = rp_prime - lp_prime
        ustar = 0.5*(phir_p + phil_p)
        rhos_l = rho_l*(pbsl/pbl + 1.0/bl)/(pbsl/(pbl*bl) + 1.0)
        rhos_r = rho_r*(pbsr/pbr + 1.0/br)/(pbsr/(pbr*br) + 1.0)
!         print*, 'Shockwave-Shockwave'
    end if
    ! Note the function phi = (phi_r - phi_l) is the output of this 
    ! subroutine, along with the corresponding velocity (ustar) and 
    ! density (rhos_l and rhos_r), and it's the function that we need to
    ! find a zero of in order to solve the exact Riemann solver
return
end
