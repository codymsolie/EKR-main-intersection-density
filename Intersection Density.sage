# Intersection Density.sage

# this file uses results from all three ekr properties to compute upper and lower bounds
# on the intersection density of a group, as well as an exact value if it is known.

class Intersection_Density:
    def __init__(self, G, ekr_determiner, ekrm_determiner):
        self.G = G
        self.has_ekr = ekr_determiner.has_ekr
        self.upper_bound = self._get_upper_bound()
        self.lower_bound = self._get_lower_bound()
        self.exact_value = self._get_exact_value()

    def _get_upper_bound(self):
        if self.has_ekr:   
            return 1
        elif len(common.larger_than_stabilizer_cocliques) >= 1: 
            # we have at least one subgroup which is larger than the stabilizer of a point, so
            # gather all subgroups with size larger than stabilizer in a list, and compute its size:
            size = max([subgroup.order() for subgroup in common.larger_than_stabilizer_cocliques])
            # use the largest order (size) to calculate an upper bound on intersection density:

            return size / (common.order / common.degree)

        return "no upper bound" # testing

    def _get_lower_bound(self):
        if self.has_ekr:
            return 1
        return "no lower bound" # testing

    def _get_exact_value(self):
        if self.has_ekr:
            return 1
        if self.upper_bound == self.lower_bound
            return upper_bound
        return "not smart enough yet"

    def _get_nice_eigenvalues(self, common): # (deg, mult) format
        eigenvalues = common.eigenvalues
        unique_eigenvalues = set(eigenvalues)
        eigenvalues = list(unique_eigenvalues)
        eigenvalues_with_multiplicities = common.eigenvalues_with_multiplicities

        eigenvalues_nice = []
        for eigenvalue in eigenvalues:
            eigenvalues_nice.append((int(eigenvalue), int(eigenvalues_with_multiplicities.count(eigenvalue))))
        eigenvalues_nice.sort()  #### must cast to int above so that values can be compared and sorted. 
        return eigenvalues_nice