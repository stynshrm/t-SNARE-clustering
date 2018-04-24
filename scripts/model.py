from modeller import *
from modeller.automodel import *    # Load the automodel class

log.verbose()
env = environ()

# directories for input atom files
env.io.atom_files_directory = ['.', '../atom_files']

class MyModel(automodel):
    def special_patches(self, aln):
        self.rename_segments(segment_ids=('B','C','D'), renumber_residues=(189, 8, 138))
    def special_restraints(self, aln):
        rsr = self.restraints
        at = self.atoms
#       Residues restraints:
        rsr.add(secondary_structure.alpha(self.residue_range('286:B', '288:B')))
        rsr.add(secondary_structure.alpha(self.residue_range('195:D', '206:D')))


a = MyModel(env, alnfile = './scripts/align.ali',
            knowns = '3hd7_bcd', sequence = 'tSN')
a.starting_model= 1
a.ending_model  = 1
#a.md_level = refine.very_fast
a.make()
