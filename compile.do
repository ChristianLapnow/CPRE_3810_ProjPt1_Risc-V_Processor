#########################################################################
# compile.do
#########################################################################
# Compiles every VHDL file in the project into the "work" library, in
# dependency order.
#
# Run from the repo root (the folder with src/ and test/):
#   in the Questa transcript:  do compile.do
#   from a terminal:           vsim -c -do "do compile.do; quit -f"
#
# Order: the RISCV_types package first (other files may use it), then
# each component before the components built from it, then testbenches.
#
# When you add a .vhd file, add it to src_files or tb_files below. The
# script stops with an error if a .vhd file anywhere under src/ or test/
# is missing from the lists, so nothing gets left out by accident.
#
# Files are compiled as VHDL-2008. They also compile as VHDL-2002
# (Questa's default): change -2008 to -2002 below if you need that.
#########################################################################

set src_files {
    src/RISCV_types.vhd

    src/invg.vhd
    src/andg2.vhd
    src/org2.vhd
    src/xorg2.vhd
    src/mux2t1.vhd
    src/mux2t1_N.vhd
    src/mux32t1_N.vhd
    src/fullAdder.vhd
    src/adder_N.vhd
    src/dffg.vhd

    src/addsub_n.vhd
    src/barrel_shifter.vhd
    src/alu.vhd

    src/control_unit.vhd

    src/Fetch/dffg_s.vhd
    src/Fetch/pcReg.vhd
    src/Fetch/fetchUnit.vhd
}

set tb_files {
    test/tb_addsub_n.vhd
    test/tb_barrel_shifter.vhd
    test/tb_alu.vhd
    test/tb_control_unit.vhd
    test/tb_fetchUnit.vhd
}

if {![file exists src/RISCV_types.vhd]} {
    error "compile.do: run this from the repo root (the folder with src/ and test/). Current folder: [pwd]"
}

# All .vhd files under dir, including subfolders.
proc vhd_files_under {dir} {
    set found [glob -nocomplain -type f [file join $dir *.vhd]]
    foreach sub [glob -nocomplain -type d [file join $dir *]] {
        set found [concat $found [vhd_files_under $sub]]
    }
    return $found
}

set all_files [concat $src_files $tb_files]
foreach f [concat [vhd_files_under src] [vhd_files_under test]] {
    if {[lsearch -exact $all_files $f] < 0} {
        error "compile.do: $f is not in the compile list. Add it to src_files or tb_files in compile.do."
    }
}

if {![file exists work]} {
    vlib work
}

foreach f $all_files {
    vcom -2008 $f
}
