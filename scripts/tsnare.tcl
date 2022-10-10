proc set_rep {m} {
    mol delrep 0 $m 
    mol selection {name "B.*"}
    mol representation DynamicBonds 4.600000 0.300000 6.000000
    mol addrep $m
    mol selection {name PO4 ROH}
    mol representation VDW 1.00000 12.000000
    mol addrep $m
}

proc gen_top {gro num_copies} {
if { [file exists "tSNARE_cg.top"] == 1} {
	mv tSNARE_cg.top tSNARE_cg.old
}
set sys_info [exec ./scripts/sys_info.sh $gro]
set ftop [open "tSNARE_cg.top" w]
set itp_file [glob Protein*.itp]
set itp_fbasename [file rootname [file tail $itp_file]
puts $ftop "#include \"./martini/martini_v2.1.itp\"
#include \"./martini/martini_v2.0_ions.itp\"
#include \"./martini/lipids.itp\"

#define RUBBER_BANDS
  
#include \"$itp_file\"
    
\[ system \]
; name
Martini system from tSNARE-TM.pdb
    
\[ molecules \]
; name        number"

puts $ftop "$itp_fbasename   $num_copies"
puts $ftop $sys_info

close $ftop
}

proc makeIndex {gro ndx} {
	exec echo q | make_ndx -f $gro -o $ndx > /dev/null 2>log.txt
	exec ./scripts/lipid_count.sh $gro > log.txt
	set ofp [open "choice.txt" w]
	puts $ofp "del 2-100"
	
	set fp [open "log.txt" r]
	set fdata [ read $fp]
	close $fp
	set data [split $fdata "\n"]
	set count 0
		foreach one $data {
		set rec [split $one "  "]
		if {[regexp {[0-9a-zA-Z]+} $rec]} {
			if {$count == 0} {
			puts -nonewline $ofp "r [lindex $rec 0]" 
			} else {
			puts -nonewline $ofp "| r [lindex $rec 0]"
			}
		incr count
		}
	}
	puts $ofp "\nname 2 BIL \n1 | 2 \na W\na W | a NA+ | a CL-\nname 5 Sol \na C* | a D* \nname 6 Tail\na GL1 | a AM1 | a ROH\nname 7 AM1_GL1_ROH\na ROH\nq "
	close $ofp

	exec make_ndx -f $gro -o $ndx -n $ndx < choice.txt > /dev/null 2>log.txt
	eval file delete [glob #*]
	eval file delete log.txt 
}

proc MakeMenu { parent opts t } {
 frame $parent.f
 pack $parent.f -side top
 set b 0
 foreach {desc proced} $opts {
    button $parent.f.$b -text $desc -command $proced -borderwidth 2 -background orange
    pack   $parent.f.$b -side left -padx 3 -pady 0
incr b
 }
}
proc Line {n} {
 frame $n -height 3 -borderwidth 2 -relief raised -background blue
 pack $n -side top -fill both -pady 5 -padx 5
} 

proc CommandEntry { name label widthl widthe var args} {
  frame $name
  label $name.l -text $label -width $widthl
  eval {entry $name.e -relief sunken -width $widthe -bg white -textvariable $var} $args
    bind $name.e  <Return>
  pack $name.l -side left
  pack $name.e -side left 
  pack  $name -fill x -padx 5
  return $name.e
}  

proc BrowseEntry { name label widthl widthe vari } {
  frame $name
  label $name.l -text $label -width $widthl
  entry $name.e -relief sunken -width $widthe -bg white -textvariable $vari
    bind $name.e  <Return>
    button $name.b  -text "Browse" ;# -command {searchPDB $vari} -text "Browse"
  pack $name.l -side left
  pack $name.e -side left 
pack $name.b -side right -padx 5
  pack  $name -fill x -padx 5
  return $name.e
}

proc DropMenu { parent label  menu_var args } {
 frame $parent
label $parent.l -text $label -width 15
eval { tk_optionMenu $parent.m  $menu_var} $args
  pack  $parent.l -side left
  pack  $parent.m -side left
  pack  $parent -fill x -padx 5
return $menu_var
}

proc CheckMenu { parent label menu_var args } {
frame $parent
label $parent.l -text $label -width 15
    eval {checkbutton $parent.cb -text "" -variable $menu_var} $args
  pack  $parent.l -side left
  pack  $parent.cb -side left
  pack  $parent -fill x -padx 5
return $menu_var
}

proc searchPDB { infile } {
upvar $infile name
set work_dir [exec pwd]
set types {
    {{All Files}        *           }
    {{PDB File}       {.pdb}        }
    {{GRO File}       {.gro}        }
    {{Topol File}     {.top}       }
    {{Index Files}    {.ndx}      }
    {{tpr Files}      {.tpr}        }
    {{mdp Files}      {.mdp}        }
    {{edr Files}      {.edr}        }
    {{xtc Files}      {.xtc}        }
    {{trr Files}      {.trr}        }
}
set name1 [tk_getOpenFile -filetypes $types]
set dir_name1 [ file  dirname  $name1 ]
if {[string match $work_dir $dir_name1]} {
     set name [ file  tail  $name1 ]
} else {
set name $name1
}
}

proc searchFolder { infile } {
upvar $infile lipDir
set lipDir [tk_chooseDirectory]
}


proc done { gui_fr } {
	mol delete all
	destroy $gui_fr
}

proc tsnare_gui {} {
    variable w
    variable pdbfile
    variable selectcolor lightsteelblue 
 # If already initialized, just turn on
  if { [winfo exists .tsnaregui] } {
    wm deiconify .tsnaregui
    return
  }
  set w [toplevel ".tsnaregui"]
  wm title $w "tsnare"

#Strat GUI
### Frame for Input:
  grid [labelframe $w.inp -bd 2 -relief ridge -text "Prepare Simulation" -padx 1m -pady 1m]\
        -row 2 -column 0 -columnspan 3 -sticky nsew
    grid [button $w.inp.b01 -text "        Build Protein       " -command {buildProt}] \
 	-row 0 -columnspan 3 -sticky w
    grid [button $w.inp.b02 -text "Build Protein Membrane system" -command {buildMemb}] \
 	-row 1 -columnspan 3 -sticky w
    grid [button $w.inp.b03 -text "Generate SA input" -command {gentpr_gui}] \
 	-row 2 -columnspan 3 -sticky w
  
  pack $w.inp -side top -padx 10 -pady 10 -expand 1 -fill x

  grid [labelframe $w.ana -bd 2 -relief ridge -text "Analyse Simulation" -padx 1m -pady 1m]\
        -row 2 -column 0 -columnspan 3 -sticky nsew
    grid [button $w.ana.b01 -text "       View Trajectory      " -command {loadTrj}] \
 	-row 0 -columnspan 3 -sticky w
 	grid [button $w.ana.b02 -text "      Lipid Enrichment      " -command {ana_enrich_gui}] \
 	-row 1 -columnspan 3 -sticky w
 	grid [button $w.ana.b03 -text "     Membrane Curvature     " -command {ana_curv_gui}] \
 	-row 2 -columnspan 3 -sticky w

 pack $w.ana -side top -padx 10 -pady 10 -expand 1 -fill x
   

 return $w
}

proc loadTrj {} {

  destroy .t
  toplevel .t
  wm title .t "Trajectory Loader"
  focus .t

BrowseEntry .t.f1  "Input Traj" 10 30 "inxtc"
.t.f1.b  configure  -command {searchPDB inxtc}

BrowseEntry .t.f2  "GRO file" 10 30 "ingro"
.t.f2.b  configure  -command {searchPDB ingro}

frame .t.cmd
  set menu_opts { "Load Trajectory" "vmdTrj $inxtc $ingro"}
  MakeMenu .t.cmd  $menu_opts x
  pack .t.cmd -pady 10

}


proc vmdTrj {outxtc ingro} {
	if { [file exists "index.ndx"] != 1} {
		#exec make_ndx -f $ingro -o ana.ndx < ./scripts/choice.txt > /dev/null 2>log.txt
		makeIndex $ingro index.ndx
	}
	mol load $ingro
	mol delrep 0 top
	mol representation DynamicBonds 4.600000 0.300000 6.000000
	mol selection {name BB}
	mol addrep top
	mol representation VDW 1.00000 12.000000
	mol selection {	name PO4 ROH}
	mol addrep top
	mol addfile $outxtc type {xtc} waitfor -1 top
}



proc buildProt {} {
	destroy .t
	toplevel .t
	wm title .t "Protein Builder"
	focus .t

	global inPDB modelPDB aliFile modScript martini_py DSSP_exe TM_val mod_succ
	set inPDB "3hd7_bcd.pdb"
	set modelPDB "tSN.B99990001.pdb"
	set modYN N  
	set martini_py "./martini/martinize-CYP.py"
	set DSSP_exe "./martini/dssp-2.0.4-linux-i386"
	set TM_val 1
	set mod_succ 0


frame .t.f1
	label .t.f1.l1 -text ""
	radiobutton .t.f1.rdb_y -text "Yes Do you have modeller installed?"   -variable modYN -value "Y" -command {fill_gui_entries $modYN}
	radiobutton .t.f1.rdb_n -text "No" -variable modYN -value "N" -command {fill_gui_entries $modYN}
	.t.f1.rdb_n select
	pack .t.f1.l1  .t.f1.rdb_y  .t.f1.rdb_n  -side right
	pack .t.f1

	BrowseEntry .t.f22  "Modeller\n executable" 10 50 "modExe"
	.t.f22.b  configure  -command {searchPDB modExe }
	BrowseEntry .t.f23  "Protein" 10 50 "inPDB"
	.t.f23.b  configure  -command {searchPDB inPDB}

frame .t.f2
	label .t.f2.l -text "Sequence\n Alignment" -width 10 
	entry .t.f2.e -relief sunken -width 50 -bg white -textvariable aliFile
	
	button .t.f2.b -text  "Browse" -command {searchPDB aliFile; fill_text $aliFile}  
	pack .t.f2.l -side left
	pack .t.f2.e -side left
	pack .t.f2.b  -side right -padx 5
	pack .t.f2 -fill x -padx 5

	BrowseEntry .t.f21  "Input\n Script" 10 50 "modScript"
	.t.f21.b  configure  -command {searchPDB modScript}

frame .t.f3
	text .t.f3.ev -width 70 -height 10 -bg white -borderwidth 3 -relief sunken -setgrid true \
		 -yscrollcommand {.t.f3.s set}
	scrollbar .t.f3.s -command {.t.f3.ev yview}
	pack .t.f3.s -side right -fill y
	pack .t.f3.ev  -fill both -expand true
	pack .t.f3 -padx 5  -pady 5

frame .t.f4
  set menu_opts {"Run Modeller" "runmod_script $modYN $modExe $modScript $modelPDB" "Use prebuilt model" "update_cys $modYN $modelPDB" }
  MakeMenu .t.f4  $menu_opts x
  pack .t.f4 -pady 10

	Line .t.lin1

	#update_cys $modelPDB
frame .t.f6
		label .t.f6.l1 -text "Select CYS to be Palmitoylated:"
		pack .t.f6.l1 

	variable listformattext "Number | Name| Chain"
	label .t.f6.l -textvar listformattext -relief flat -justify left
 
  	listbox .t.f6.list -activestyle dotbox \
    -font {tkFixed 9} -width 20 -height 8 -setgrid 1 -selectmode extended \
    -selectbackground lightsteelblue -listvariable cys_res_list
	pack .t.f6.l -side top -anchor w
	pack .t.f6.list -side left  -fill y -expand 1
	button .t.f6.b -text  "Palmitoylate selected \n CYS resdiues" -command {push_cys}
	pack .t.f6.b -side left
	pack .t.f6

	Line .t.lin2
	CheckMenu .t.f7 "Select TM Domain" "TM_val"
	BrowseEntry .t.f8  "Martinize" 10 30 "martini_py"
	.t.f8.b  configure  -command {searchPDB martini_py}
	BrowseEntry .t.f9  "DSSP exe" 10 30 "DSSP_exe"
	.t.f9.b  configure  -command {searchPDB DSSP_exe}

frame .t.cmds
	set menu_opts { "Martinize & Minimize" RUN_MARTINI  "Exit" "done .t"}
	MakeMenu .t.cmds  $menu_opts x
	pack .t.cmds -pady 10


}

proc fill_text {filename} {
    set f [open $filename r]
    set data [read $f]
    close $f
    .t.f3.ev delete 0.0 end
    .t.f3.ev insert 0.0 $data
}

proc fill_gui_entries {modYN} {
	global inPDB aliFile modScript  
	if {$modYN == "Y"} {
		set inPDB "3hd7_bcd.pdb"
		set aliFile "./scripts/align.ali"
		set modScript "./scripts/model.py"
		fill_text $aliFile
	} else {
		.t.f3.ev delete 0.0 end
		set inPDB "3hd7_bcd.pdb"
	        set aliFile ""
		set modScript ""

	}
}
proc runmod_script {modYN modExe filename oPDB} {
	global mod_succ 0
	if {$modYN == "N"} { 
		.t.f3.ev insert end "Modeller is not available!" 
		} else {
			.t.f3.ev tag configure highlightline -background yellow -font "helvetica 14 bold" -relief raised
			exec $modExe $filename > /dev/null 2>log.txt
			file delete tSN.D00000001  tSN.ini  tSN.rsr  tSN.sch  tSN.V99990001 log.txt
			
			if { [file exists $oPDB] == 1} { 
				.t.f3.ev delete 0.0 end
				.t.f3.ev insert end "Model created : $oPDB" "highlightline"
				set mod_succ 1
				update_cys $modYN $oPDB 
				} else {
					.t.f3.ev insert end "Modeller failed" "highlightline"
					set logTxt [exec tail -10 model.log]
					.t.f3.ev insert end "$logTxt"
#					update_cys $modYN $oPDB 
			}
	}
}


proc update_cys {modYN oPDB} {
global cys_res_list mod_succ
	if {$mod_succ == 0} { 
		.t.f3.ev delete 0.0 end
		.t.f3.ev insert end "skipping Modeller\n Using pre-built model\n"
	exec cp ./scripts/tSN.B99990001.pdb $oPDB
	} 
    if { [file exists $oPDB] == 1} { 
	mol delete all
    mol load pdb $oPDB
    set selall [atomselect top all]
    $selall move [transinertia $selall]
    $selall writepdb $oPDB 
	set sel1 [atomselect top "resname CYS and name CA"]
	set cys_res_list  [$sel1 get {resid resname chain}]
}
}

proc transinertia {sel} {
    set m [lindex [measure inertia $sel] 1]
    set v0 "[lindex $m 0] 0"
    set v1 "[lindex $m 1] 0"
    set v2 "[lindex $m 2] 0"
    set v3 "0 0 0 1"
    set m4 [list $v0 $v1 $v2 $v3]
    return $m4
} 

proc push_cys {} {
	package require topotools 
	global cys_res_list
	set cys_id [.t.f6.list curselection]

	set cys_id_list [regexp -all -inline {\S+} $cys_id]
	foreach var $cys_id_list {
		set res_id [lindex [lindex $cys_res_list $var] 0]
		set ch [lindex [lindex $cys_res_list $var] 2]
		puts "$res_id .. $ch"
		
		
		#set sel_all [atomselect top "all"]
		#set all_ind [$sel_all num]
		set all_ind [molinfo top get numatoms]
		
		set sel_cys_O [atomselect top "resid $res_id and chain $ch and name O"]
		set tmp_ndx [$sel_cys_O get index]
		set seg1 [atomselect top "index 0 to $tmp_ndx"]
		
		set seg3_ndx [expr $tmp_ndx+1]
		set seg3 [atomselect top "index $seg3_ndx to $all_ind"]

		set sel_cys [atomselect top "resid $res_id and chain $ch"]
		$sel_cys set resname CYP

		$sel_cys writepdb tmp_00.pdb
		eval exec echo 1 1 | gmx confrms -one -f1 tmp_00.pdb  -f2 scripts/cyp-AT.pdb  -name -o cysfit.pdb > /dev/null 2>cyp.txt
		mol load pdb cysfit.pdb
		mol delrep 0 top
		set plm [atomselect top "all and not name N CA CB C O SG"]
		$plm set resname CYP
		$plm set resid $res_id
		mol representation Licorice 12 0.3 12
		mol selection {all and not name N CA CB C O}
		mol addrep top

		set mol_palm [::TopoTools::selections2mol "$seg1 $plm $seg3"] 
		animate write pdb tSN_cys.pdb $mol_palm
		#and now write modified pdb and load
		mol delete all
		mol load pdb tSN_cys.pdb
		mol representation Licorice 0.3 15.00 12.00
		mol color ColorID 4 
		mol selection {resname CYP and not name N CA CB C O}
		mol addrep top
	}
	eval file delete [glob #*]
	eval file delete cyp.txt cysfit.pdb tmp_00.pdb
}

proc RUN_MARTINI {} {
	global martini_py DSSP_exe TM_val
	if { $TM_val == 1} {
		set TM [atomselect top "(resid 247 to 288 and chain B) or (resid 74 to 98 and chain C) or (resid 195 to 206 and chain D)"]
		$TM writepdb tSNARE-TM.pdb
		exec python $martini_py -f tSNARE-TM.pdb -o tSNARE_cg.top -x tSNARE_cg.pdb -dssp $DSSP_exe -elastic -ef 1000 -ff martini21 -merge all > /dev/null 2>log.txt
	} else {
		exec python $martini_py -f tmp_cys.pdb -o tSNARE_cg.top -x tSNARE_cg.pdb -dssp $DSSP_exe -elastic -ef 1000 -ff martini21 -merge all > /dev/null 2>log.txt
	}
	set itp_file [glob Prot*.itp]
	#set itp_fbasename [file rootname [file tail $tclfiles]
    exec cat ./scripts/posre.itp >> $itp_file
	exec editconf -f tSNARE_cg.pdb -o tSNARE_cg.gro -d 2.0 > /dev/null 2>log.txt
	exec grompp -f ./scripts/minim.mdp -c tSNARE_cg.gro -p tSNARE_cg.top -maxwarn 5 -o em-01.tpr > /dev/null 2> log.txt
	exec mdrun -deffnm em-01  -c tSNARE-TM_em.gro > /dev/null 2>log.txt
	eval file delete log.txt 
	eval file delete [glob em-01.*]
	#eval file delete [glob #*]
	mol delete all
	mol load gro tSNARE-TM_em.gro
	mol representation DynamicBonds 4.600000 0.300000 6.000000
	mol addrep top
	mol representation VDW 1.00000 32.000000
	mol selection {resname CYP}
	mol addrep top
}


proc buildMemb {} {
  destroy .t
  toplevel .t
  wm title .t "Membrane Builder"
  focus .t
	global ic_lipids ec_lipids outgro ovlap lipDir groname x_vec y_vec z_vec x_num y_num x_sep y_sep inPDB sep_dist 

	set ic_lipids "POPE 43 PAPE 114 PUPE 44 DUPE 141 POPS 20 PAPS 15 PUPS 97 POP2 6 PAP2 26 PUP2 3 CHOL 176"
	set ec_lipids "DPPC 168 POPC 187 PAPC 38 PUPC 23 DPSM 46 DBSM 3 DXSM 2 PNSM 1 DPG1 20 DPG3 20 CHOL 263"
	set lipDir "./martini"
	set outgro memb.gro
	set ovlap 0.50
	set x_vec 27.0
	set y_vec 27.0
	set z_vec 14.0
	set x_num 4
	set y_num 3
	set x_sep 2.5
	set y_sep 2.5
	set inPDB tSNARE-TM_em.gro
	set sep_dist 2.5
	
    

	BrowseEntry .t.f1  "Lipid PDBs" 10 30 "lipDir"
	.t.f1.b  configure  -command {searchFolder lipDir}
	CommandEntry .t.f2  "Output GRO file" 15 30 "outgro"  
	label .t.ab -text ""
	pack  .t.ab
	label .t.yy -text "Define Box dimension:" -font "fixed 12 bold"
	pack  .t.yy

frame .t.fr6
	label .t.fr6.l -text "Box vec (nm)" -width 15
	entry .t.fr6.e1 -relief sunken -width 10 -bg white -textvariable "x_vec"
	entry .t.fr6.e2 -relief sunken -width 10 -bg white -textvariable "y_vec"
	entry .t.fr6.e3 -relief sunken -width 10 -bg white -textvariable "z_vec"
	pack .t.fr6.l -side left
	pack .t.fr6.e1 -side left
	pack .t.fr6.e2 -side left
	pack .t.fr6.e3 -side left
	pack .t.fr6  -fill x -padx 5

frame .t.e
  label .t.e.bb -text ""
  pack  .t.e.bb  -fill x
  label .t.e.b -text "Add Lipid Type and Number " -font "fixed 12 bold"
  pack .t.e.b
  pack  .t.e -side top
        frame .t.e.f
        pack .t.e.f 
                frame .t.e.f.f1
                pack .t.e.f.f1
                label .t.e.f.f1.l -text "Add Intracellular Lipids:(e.g., POPE 25 POPS 18 )"
                pack  .t.e.f.f1.l
                text .t.e.f.f1.ev -width 30 -height 5 -bg white \
                -borderwidth 3 -relief sunken -setgrid true \
                -yscrollcommand {.t.e.f.f1.s set} 
                scrollbar .t.e.f.f1.s -command {.t.e.f.f1.ev yview}
                pack .t.e.f.f1.s -side right -fill y 
                pack .t.e.f.f1.ev  -fill both -expand true
.t.e.f.f1.ev insert end $ic_lipids
##Addnl frame
                frame .t.e.f.f2
                pack .t.e.f.f2
                label .t.e.f.f2.l -text "Add Extracellular Lipids:(e.g., DPPC 20 POPC 17 ..)"
                pack  .t.e.f.f2.l -fill x
                text .t.e.f.f2.ev -width 30 -height 5 -bg white \
                  -borderwidth 3 -relief sunken -setgrid true \
                  -yscrollcommand {.t.e.f.f2.s set}
                scrollbar .t.e.f.f2.s -command {.t.e.f.f2.ev yview}
                pack .t.e.f.f2.s -side right -fill y 
                pack .t.e.f.f2.ev  -fill both -expand true
                frame .t.e.f.f3
                pack .t.e.f.f3
.t.e.f.f2.ev insert end $ec_lipids

frame .t.cmds
  set menu_opts { "Generate Membrane" RUN_EDCONF }
  MakeMenu .t.cmds  $menu_opts x
  pack .t.cmds -pady 10

	Line .t.lin1
	BrowseEntry .t.f8  "Select Protein " 10 30 "inPDB"
	.t.f8.b  configure  -command {searchPDB inPDB}

frame .t.fr9
	label .t.fr9.l -text "Place Protein on Grid " -font "fixed 12 bold"
	pack .t.fr9.l
	label .t.fr9.l1 -text "Monomers \nalong x " -width 10
	entry .t.fr9.e1 -relief sunken -width 10 -bg white -textvariable "x_num"
	label .t.fr9.l2 -text "Distance between \nmonomers (nm)" -width 15
	entry .t.fr9.e2 -relief sunken -width 10 -bg white -textvariable "x_sep"
	pack .t.fr9.l1 -side left
	pack .t.fr9.e1 -side left
	pack .t.fr9.l2 -side left
	pack .t.fr9.e2 -side left
	pack .t.fr9 -fill x -padx 5

frame .t.fr10
	label .t.fr10.l1 -text "Monomers \nalong y " -width 10
	entry .t.fr10.e1 -relief sunken -width 10 -bg white -textvariable "y_num"
	label .t.fr10.l2 -text "Distance between \nmonomers (nm)" -width 15
	entry .t.fr10.e2 -relief sunken -width 10 -bg white -textvariable "y_sep"
	pack .t.fr10.l1 -side left
	pack .t.fr10.e1 -side left
	pack .t.fr10.l2 -side left
	pack .t.fr10.e2 -side left
	pack .t.fr10 -fill x -padx 5

#CommandEntry .t.f9  "Separtion distance\n(nm)" 15 30 "sep_dist"
frame .t.cmd2
  set menu_opts { "Generate copies " Gen12x }
  MakeMenu .t.cmd2  $menu_opts x
  pack .t.cmd2 -pady 10

	Line .t.lin2
 
frame .t.cmd3
  set menu_opts {"Save System" save_box "Exit" "done .t"}
  MakeMenu .t.cmd3  $menu_opts x
  pack .t.cmd3 -pady 10

}

proc RUN_EDCONF {} {
    global lipDir groname ec_lipids ic_lipids x_vec y_vec z_vec ic_id ec_id
    set ic_lipids [.t.e.f.f1.ev get 1.0 end]
    set ec_lipids [.t.e.f.f2.ev get 1.0 end]
    
	set lcnt [open "lipid_count.log" w]
	set var [llength $ic_lipids]
	for {set i 0} {$i < $var} {incr i 2} {
		set j [expr $i+1]
		set lip [lindex $ic_lipids $i]
		set num [lindex $ic_lipids $j]
		if { $i == 0 } {
			exec genbox -ci $lipDir/$lip.pdb -nmol $num  -o icbox0.gro -box $x_vec $y_vec 5.0  >&icbox.log
			set output [exec grep "Added" icbox.log]
			#exec grep "Added" ecbox.log | awk '{print $2}' >> lipids.log
			puts "$output"
			puts $lcnt "$lip  [lindex $output 1]"
		} else {
			exec genbox -ci $lipDir/$lip.pdb -cp icbox0.gro -nmol $num  -o icbox0.gro -box $x_vec $y_vec 5.0 -try 500 >&icbox.log
			set output [exec grep "Added" icbox.log]
			#exec grep "Added" ecbox.log | awk '{print $2}' >> lipids.log
			puts "$output"
			puts $lcnt "$lip  [lindex $output 1]"
		}  
}

	set var [llength $ec_lipids]
	for {set i 0} {$i < $var} {incr i 2} {
		set j [expr $i+1]
		set lip [lindex $ec_lipids $i]
		set num [lindex $ec_lipids $j]
		if { $i == 0 } {
			exec genbox -ci $lipDir/$lip.pdb -nmol $num  -o ecbox0.gro -box $x_vec $y_vec 5.0  >&ecbox.log
			set output [exec grep "Added" ecbox.log]
			#exec grep "Added" ecbox.log | awk '{print $2}' >> lipids.log
			puts "$output"
			puts $lcnt "$lip  [lindex $output 1]"
		} else {
			exec genbox -ci $lipDir/$lip.pdb -cp ecbox0.gro -nmol $num  -o ecbox0.gro -box $x_vec $y_vec 5.0 -try 500 >&ecbox.log
			set output [exec grep "Added" ecbox.log]
			#exec grep "Added" ecbox.log | awk '{print $2}' >> lipids.log
			puts "$output"
			puts $lcnt "$lip  [lindex $output 1]"
		}  
	}
	close $lcnt
	
	set Xmid [expr $x_vec/2]
	set Ymid [expr $y_vec/2]
	exec editconf -f icbox0.gro -o box_ic.gro -box $x_vec $y_vec $z_vec -center $Xmid $Ymid 7.0 > /dev/null 2>log.txt
	exec editconf -f ecbox0.gro -o box_ec.gro -box $x_vec $y_vec $z_vec -center $Xmid $Ymid 2.5 > /dev/null 2>log.txt
	#mol delete all
	mol new {box_ic.gro} type {gro} waitfor all
	set ic_id [molinfo top get id]
	mol color ColorID 3
	mol addrep top
	mol representation VDW 1.00000 12.000000
    mol selection {name PO4}
    mol addrep top
	mol new {box_ec.gro} type {gro} waitfor all
	set ec_id [molinfo top get id]
	mol color ColorID 13
	mol addrep top
	mol representation VDW 1.00000 12.000000
    mol selection {name PO4}
    mol addrep top
	eval file delete [glob #*]
	eval file delete log.txt icbox.log ecbox.log icbox0.gro ecbox0.gro
}


proc Gen12x {} {
	global inPDB x_vec y_vec sep_dist x_num y_num x_sep y_sep prot_id 

	exec editconf -f $inPDB -d 0 -o temp1.pdb > /dev/null 2>log.txt
	exec genconf -f temp1.pdb -o temp1.gro -nbox $x_num 1 1 -dist $x_sep > /dev/null 2>log.txt
	exec editconf -f temp1.gro -d 0 -o temp2.pdb > /dev/null 2>log.txt
	exec genconf -f temp2.pdb -o temp3.pdb -nbox 1 $y_num 1 -dist $y_sep > /dev/null 2>log.txt
	exec editconf -f temp3.pdb -o temp3.gro -d 1.25 -c  > /dev/null 2>log.txt
	exec editconf -f temp3.gro -o 12x-tSNARE_cg.gro  -translate 2.0 2.0 2.5 > /dev/null 2>log.txt
	eval file delete [glob temp*]
	eval file delete log.txt
	#check the protein box size
	set box [exec tail -1 12x-tSNARE_cg.gro]
	set a [lindex $box 0]
	set b [lindex $box 1]
	if {$a > $x_vec} { 
		tk_messageBox -message "Protein box along x-axis is bigger than membrane.\n Try reducing the number or distance between monomers to slightly smaller value" -type ok 
		eval file delete 12x-tSNARE_cg.gro
	} elseif {$b > $y_vec} {
		tk_messageBox -message "Protein box along y-axis is bigger than membrane.\n Try reducing the number or distance between monomers to slightly smaller value" -type ok 
		eval file delete 12x-tSNARE_cg.gro
	} else {
		mol new 12x-tSNARE_cg.gro type gro
		mol representation VDW 1.00000 12.000000
	     mol color ColorID 4
	    mol addrep top
	    set prot_id [molinfo top get id] 
  	}
}


proc save_box {} {
	global x_vec y_vec z_vec prot_id ic_id ec_id x_num y_num sysgro topname num_copies
	package require topotools 
	set seg1 [atomselect $prot_id "all"]
	set seg2 [atomselect $ic_id "all"]
	set seg3 [atomselect $ec_id "all"]
	set mol_all [::TopoTools::selections2mol "$seg1 $seg2 $seg3"]
	animate write pdb temp.pdb $mol_all
	set sysgro 12xtSNARE_BIL.gro
	exec editconf -f temp.pdb -o $sysgro -box $x_vec $y_vec $z_vec -c > /dev/null 2>log.txt

	#update topol
	set num_copies [expr $x_num * $y_num]
	set topname "tSNARE_cg.top"
	set itp_file [glob Protein*.itp]
	set itp_fbasename [file rootname [file tail $itp_file]
	
	set f [open $topname]
	set theLines [split [read $f] "\n"]
	close $f
	set theLines [lreplace $theLines end end]
	set f [open $topname "w"]
	puts -nonewline $f [join $theLines "\n"]
	puts  $f "\n$itp_fbasename  $num_copies" 
	close $f

	exec cat lipid_count.log >> tSNARE_cg.top
	eval file delete [glob temp*.pdb]
	eval file delete log.txt
	tk_messageBox -message "Simulation box ready!!!\nFinal Structure : \"$sysgro\"\nFinal Topolgy : \"tSNARE_cg.top\"" -type ok 
 # destroy $gui_fr
}

proc gentpr_gui {} {
	  destroy .t
	  toplevel .t
	  wm title .t "Generate MD run input"
	  focus .t
	
	global sysgro topname systpr mdp_type num_copies add_WION
	set sysgro 12xtSNARE_BIL.gro
	set topname tSNARE_cg.top
	set systpr sa-01.tpr
	set num_copies 12


	BrowseEntry .t.f1  "Input gro" 10 30 "sysgro"
	.t.f1.b  configure  -command {searchPDB sysgro}
	
	BrowseEntry .t.f2  "Topology" 10 30 "topname"
	.t.f2.b  configure  -command {searchPDB topname}

	CommandEntry .t.fc1  "Number of \nProtein copies" 15 30 "num_copies"
	CheckMenu .t.fc2  "Add solvent \nand minimize" "add_WION"

frame .t.f5
	label .t.f5.l -text "Generate MD run Input file " -font "fixed 12 bold"
	pack .t.f5.l
	pack .t.f5

	BrowseEntry .t.f6  "Output TPR" 10 30 "systpr"
	.t.f6.b  configure  -command {searchPDB systpr}

	DropMenu .t.f8 "Choose MD\nparameter file:" "mdp_type" self_assembly.mdp mdrun.mdp

frame .t.cmd
  set menu_opts { "Generate" "GenboxMin" "Exit" "done .t"}
  MakeMenu .t.cmd  $menu_opts x
  pack .t.cmd -pady 10

}

proc GenboxMin {} {
	global sysgro topname num_copies mdp_type add_WION

	if {$add_WION} {
	exec genbox -cp $sysgro -cs ./martini/water.gro -o sysgro_W.gro -p $topname -vdwd 0.22 > /dev/null 2>log.txt
	gen_top sysgro_W.gro $num_copies
	
	exec grompp -f ./scripts/minim.mdp -c sysgro_W.gro -p $topname -o ions.tpr -maxwarn 10 > /dev/null 2>log.txt
	makeIndex sysgro_W.gro index.ndx
	
	exec echo W | genion -s ions.tpr -o sysgro_WI.gro -p $topname -pname NA+ -nname CL- -neutral -n index.ndx -conc 0.1 > /dev/null 2>log.txt

	exec grompp -f ./scripts/minim.mdp -c sysgro_WI.gro -p $topname -o em-01.tpr -maxwarn 5  > /dev/null 2>log.txt
	exec mdrun_d -nt 4 -deffnm em-01  > /dev/null 2>log.txt
	exec grompp -f ./scripts/em.mdp -c em-01.gro -p $topname -o em-02.tpr -maxwarn 5  > /dev/null 2>log.txt
	exec mdrun -nt 4 -deffnm em-02  -c em-02.gro > /dev/null 2>log.txt
	set logtxt [exec tail -6 log.txt | head -3 ]
	tk_messageBox -message "Mimimization complete:\n$logtxt" -type ok
	} else {
		exec editconf -f $sysgro -o em-02.gro > /dev/null 2>log.txt
	}
	makeIndex em-02.gro index.ndx
	gen_top em-02.gro $num_copies

 	exec grompp -f $mdp_type -c em-02.gro -p $topname -n index.ndx -o $systpr - maxwarn 5 > /dev/null 2>log.txt
	exec rm -f log.txt
	if { [file exists $systpr] == 1} {
		tk_messageBox -message "Created mdrun input $systpr !" -type ok
	} else {
		tk_messageBox -message "Failed to create mdrun input $systpr !" -type ok
}

	eval file delete log.txt ions.tpr 
	eval file delete [glob em-0*]
	eval file delete [glob sysgro*]
	eval file delete [glob #*]
}

proc ana_enrich_gui {} {
	destroy .t
	toplevel .t
	wm title .t "Lipid Enrichment"
	focus .t

	BrowseEntry .t.f1  "Trajectory (xtc)" 15 30 "inxtc"
	.t.f1.b  configure  -command {searchPDB inxtc}
	BrowseEntry .t.f2  "Structure (gro)" 15 30 "ingro"
	.t.f2.b  configure  -command {searchPDB ingro}
	BrowseEntry .t.f3  "MD Run\n Input (tpr) " 15 30 "intpr"
	.t.f3.b  configure  -command {searchPDB intpr}

   frame .t.f31
	label .t.f31.l1 -text "Analysis will be done on frames between:"
	pack .t.f31.l1
	pack .t.f31

	CommandEntry .t.f4  "Start time (ns)" 15 30 "db"
	CommandEntry .t.f5  "End time   (ns)" 15 30 "de"
	CommandEntry .t.f6  "Time Step  (ns)" 15 30 "dt"
	DropMenu .t.f7 "Analyse lipid type:" "lip_type" PIP2 GM {CHOL IC} {CHOL EC}

   frame .t.cmd
	set menu_opts { "Analyse Enrichment" "ana_enrich $inxtc $ingro $intpr $db $de $dt $lip_type"}
	MakeMenu .t.cmd  $menu_opts x
	pack .t.cmd -pady 10
}


proc ana_enrich {inxtc ingro intpr db de dt lip_type} {
	if { [file exists "ana_curv.ndx"] != 1} {
		#exec make_ndx -f $ingro -o ana_curv.ndx < ./scripts/choice.txt > log.txt
		makeIndex $ingro ana_curv.ndx
	}
	set dtps [expr $dt*1000]
	set deps [expr $de*1000]
	set dbps [expr $db*1000]
	
	if { [file exists "AM1_GL1_ROH.xtc"] != 1} {
	exec echo Protein Protein_BIL | trjconv -f $inxtc -s $intpr -dt $dtps -o tmp.xtc -b $dbps -e $deps -n ana_curv.ndx -pbc cluster > /dev/null 2>log.txt
	exec echo Protein_BIL | tpbconv -s $intpr -o noSOL.tpr -n ana_curv.ndx > /dev/null 2>log.txt
	exec echo Protein Protein_BIL | trjconv -f tmp.xtc -s noSOL.tpr -n ana_curv.ndx -o cent.xtc -pbc res -center > /dev/null 2>log.txt
	exec echo Protein Protein_BIL | trjconv -f cent.xtc -s noSOL.tpr -n ana_curv.ndx -o fit.xtc -fit progressive  > /dev/null 2>log.txt
	exec echo Protein_BIL | trjconv -f fit.xtc -s noSOL.tpr -n ana_curv.ndx -o fit.gro -dump $deps  > /dev/null 2>log.txt
	exec echo AM1_GL1_ROH | trjconv -f fit.xtc -s noSOL.tpr -n ana_curv.ndx -o AM1_GL1_ROH.xtc > /dev/null 2>log.txt
	exec echo AM1_GL1_ROH | trjconv -f fit.xtc -s noSOL.tpr -n ana_curv.ndx -o AM1_GL1_ROH.gro -dump $dbps > /dev/null 2>log.txt
	
	set fp [open "lip.txt" w]
	puts $fp "del 0-100"
	puts $fp "r POP2 | r PAP2 | r PUP2"
	puts $fp "r DPG1 | r DPG3"
	puts $fp "name 0 PIP2"
	puts $fp "name 1 GM1"
	puts $fp "q"
	close $fp

	exec make_ndx -f AM1_GL1_ROH.gro -o lip.ndx < lip.txt > /dev/null 2>log.txt

	mol delete all
	mol new fit.gro type {gro} waitfor all
	set_rep 0
	mol new AM1_GL1_ROH.gro type {gro} waitfor all
	mol addfile AM1_GL1_ROH.xtc type {xtc} waitfor -1 top
	chol_split
	mol delete top
	}
	
	eval file delete tmp.xtc cent.xtc log.txt lip.txt
	if {$lip_type == "PIP2"} {

		exec echo PIP2 | g_densmap -f AM1_GL1_ROH.xtc -s AM1_GL1_ROH.gro -o PIP2.xpm -bin 0.1 -n lip.ndx > /dev/null 2>log.txt
		exec xpm2ps -f PIP2.xpm -o PIP2.eps -rainbow blue -yonce -di scripts/inp.m2p > /dev/null 2>log.txt
		exec display PIP2.eps &
	}
	if {$lip_type == "GM"} {
		exec echo GM1 | g_densmap -f AM1_GL1_ROH.xtc -s AM1_GL1_ROH.gro -o GM.xpm -bin 0.1 -n lip.ndx > /dev/null 2>log.txt
		exec xpm2ps -f GM.xpm -o GM.eps -rainbow blue -yonce -di scripts/inp.m2p > /dev/null 2>log.txt
		exec display GM.eps &
	}
	if {$lip_type == "CHOL IC"} {
		puts "$lip_type"
	    exec echo 0 | g_densmap -f UPPER.pdb -s UPPER.pdb -o up_chol.xpm -bin 0.1 > /dev/null 2>log.txt
	    exec xpm2ps -f up_chol.xpm -o up_chol.eps -rainbow blue -yonce -di scripts/inp.m2p > /dev/null 2>log.txt
	    exec display up_chol.eps &
	    }
	if {$lip_type == "CHOL EC"} {
		puts "$lip_type"
	    exec echo 0 | g_densmap -f LOWER.pdb -s LOWER.pdb -o lo_chol.xpm -bin 0.1 > /dev/null 2>log.txt
	    exec xpm2ps -f lo_chol.xpm -o lo_chol.eps -rainbow blue -yonce -di scripts/inp.m2p > /dev/null 2>log.txt
	    exec display lo_chol.eps &
	    }
}

proc chol_split {} {
	set membrane [atomselect top "name AM1 GL1"]
	set upper [atomselect top "name AM1 GL1 and z > [lindex [measure center $membrane] 2]"]
	set lower [atomselect top "name AM1 GL1 and z < [lindex [measure center $membrane] 2]"]
	set numframes [molinfo top get numframes]
	for {set i 0} {$i < $numframes} {incr i} {
		$membrane frame $i
		$upper frame $i
		$lower frame $i
		$membrane update
		$upper update
		$lower update
		set upndx [$upper get index]
		set londx [$lower get index]
		set chol_up [atomselect top "name ROH and within 8.0 of index $upndx" frame $i]
		set chol_lo [atomselect top "name ROH and within 8.0 of index $londx" frame $i]
		$chol_up writepdb up_chol_$i.pdb
		$chol_lo writepdb lo_chol_$i.pdb
	}
	exec grep CRYST up_chol_0.pdb > UPPER.pdb
	set flist [glob up_chol*.pdb]
	foreach f $flist {
	exec grep ATOM $f >> UPPER.pdb
	}
	exec grep CRYST lo_chol_0.pdb > LOWER.pdb
	set flist [glob lo_chol*.pdb]
	foreach f $flist {
	exec grep ATOM $f >> LOWER.pdb
	}
	eval file delete [glob up_chol*.pdb]
	eval file delete [glob lo_chol*.pdb]
}

proc ana_curv_gui {} {
  destroy .t
  toplevel .t
  wm title .t "Membrane Curvature"
  focus .t

	BrowseEntry .t.f1  "Trajectory (xtc)" 15 30 "inxtc"
	.t.f1.b  configure  -command {searchPDB inxtc}
	BrowseEntry .t.f2  "Structure (gro)" 15 30 "ingro"
	.t.f2.b  configure  -command {searchPDB ingro}
	BrowseEntry .t.f3  "MD Run\n Input (tpr) " 15 30 "intpr"
	.t.f3.b  configure  -command {searchPDB intpr}
frame .t.f31
	label .t.f31.l1 -text "Analysis will be done on frames between:"
	pack .t.f31.l1
	pack .t.f31

	CommandEntry .t.f4  "Start time (ns)" 15 30 "db"
	CommandEntry .t.f5  "End time   (ns)" 15 30 "de"
	CommandEntry .t.f6  "Time Step  (ns)" 15 30 "dt"

frame .t.cmd
	set menu_opts { "Show Curvature" "ana_curv $inxtc $ingro $intpr $db $de $dt"}
	MakeMenu .t.cmd  $menu_opts x
	pack .t.cmd -pady 10

}


proc ana_curv {inxtc ingro intpr db de dt} {
	if { [file exists "ana_curv.ndx"] != 1} {
		#exec make_ndx -f $ingro -o ana_curv.ndx < ./scripts/choice.txt > /dev/null 2>log.txt
		makeIndex $ingro ana_curv.ndx
	}
	set dtps [expr $dt*1000]
	set deps [expr $de*1000]
	set dbps [expr $db*1000]
	if { [file exists "cent.xtc"] != 1} {
	exec echo Protein Protein_BIL | trjconv -f $inxtc -s $intpr -dt $dtps -o tmp.xtc -b $dbps -e $deps -n ana_curv.ndx -pbc cluster > /dev/null 2>log.txt
	exec echo Protein_BIL | tpbconv -s $intpr -n ana_curv.ndx -o noSOL.tpr  > /dev/null 2>log.txt
	exec echo Protein Protein_BIL | trjconv -f tmp.xtc -s noSOL.tpr -n ana_curv.ndx -o cent.xtc -pbc res -center  > /dev/null 2>log.txt
	exec echo Protein_BIL | trjconv -f cent.xtc -s noSOL.tpr -n ana_curv.ndx -o cent.gro -dump $deps  > /dev/null 2>log.txt
	exec rm -f tmp.xtc log.txt
	exec echo Tail | trjconv -f cent.xtc -s noSOL.tpr -pbc atom -n ana_curv.ndx -o dump.pdb > /dev/null 2>log.txt
	}
	#eval exec grep CRYS dump.pdb | head -1  > tail.pdb
	set outbox [exec grep -m 1 CRYS dump.pdb]
	exec echo $outbox > tail.pdb
	set out_x [lindex $outbox 1]
	set out_y [lindex $outbox 2]
	exec grep ATOM dump.pdb >> tail.pdb
	#VMD
	mol new cent.gro type {gro} waitfor all
	set_rep 0
	mol new tail.pdb type {pdb} waitfor all
	mol delrep 0 top
	mem_surf $out_x $out_y
	mol new av_memb.xyz type {xyz} waitfor all
	mol modstyle 0 top VDW 1.00000 12.000000
	mol modcolor 0 top PosZ
	set aa [atomselect top all]
	::ColorScaleBar::color_scale_bar 0.5  0.05  0  128 [lindex [lindex [measure minmax $aa] 0] 2] [lindex [lindex [measure minmax $aa] 1] 2]
	mol fix 3
	color Display Background white
}

proc mem_surf {out_x out_y} {
	set fout "av_memb.dat"
	set f [open $fout w]
	set w 10
	for {set x 0} { $x < $out_x } { incr x $w} {
	for {set y 0} { $y < $out_y } { incr y $w} {
		set x_up [expr {$x+$w}]
		set y_up [expr {$y+$w}]
		set mem [atomselect top "all and x>=$x and x < $x_up and y>=$y and y < $y_up"]
	puts $f "X  [lindex [measure center $mem] 0] [lindex [measure center $mem] 1] [lindex [measure center $mem] 2]"
	}
	}
	close $f
	set natoms [ exec wc -l av_memb.dat]
	set fout "av_memb.xyz"
	set f [open $fout w]
	puts $f "$natoms\n"
	close $f
	exec cat av_memb.dat >> av_memb.xyz
}

tsnare_gui
