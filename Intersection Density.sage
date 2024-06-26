# Intersection Density.sage

# this file uses results from common and ekr_determiner to compute upper and lower bounds
# on the intersection density of a group, as well as an exact value if it is known.

class Intersection_Density:
    def __init__(self, G, ekr_determiner):
        self.G = G
        self.has_ekr = ekr_determiner.has_ekr
        self.upper_bound = self._get_upper_bound()
        self.lower_bound = self._get_lower_bound()
        self.exact_value = self._get_exact_value()

###### DRIVER FUNCTIONS

    def _get_upper_bound(self):
      if self.has_ekr:
        return 1
      return min([
        (self.G.order / 2),
        self.ub_clique_coclique(),
        self.ub_no_homomorphism(),
        self.ub_ratio_bound()  # needs work
      ])

    def _get_lower_bound(self):
      if self.has_ekr
        return 1
      return self.lb_larger_than_stabilizer_cocliques() #this is our only lower bound

    def _get_exact_value(self):
      if self.has_ekr:
        return 1

      if self.upper_bound == self.lower_bound:
          return self.upper_bound

      if self.G.is_a_complete_multipartite:
        tau = gap.AbsoluteValue(self.G.min_eigenvalue)
        self.upper_bound = tau / (self.G.size_of_stabilizer)
        self.lower_bound = tau / (self.G.size_of_stabilizer)
        return tau / (self.G.size_of_stabilizer)

      if self.G.is_a_join:
        H = self.subgroup_by_non_derangements()
        non_der_common = Common(H)
        non_der_ekr = EKR_Determiner(non_der_common)
        non_der_int_dens = Intersection_Density(non_der_common, non_der_ekr)
        if non_der_int_dens.upper_bound < self.upper_bound:
          self.upper_bound = non_der_int_dens.upper_bound
        if non_der_int_dens.lower_bound > self.lower_bound:
          self.lower_bound = non_der_int_dens.lower_bound
        return non_der_int_dens.exact_value

      return -1

###### HELPER FUNCTIONS

    def lb_larger_than_stabilizer_cocliques(self):
      if len(self.G.larger_than_stabilizer_cocliques) >= 1:
        max_size = int(max([
          subgroup.order() for subgroup in self.G.larger_than_stabilizer_cocliques
        ]))
        return max_size / self.G.size_of_stabilizer
      return (self.G.order / 2) # worst possible bound if nothing is found here

    def ub_clique_coclique(self):
      largest_clique_size = 2 #initializing to smallest clique size 
      for subgroup in self.G.subgroups:
        subgroup_common = Common(subgroup)
        if subgroup_common.min_eigenvalue == -1 and subgroup_common.order > largest_clique_size:
          largest_clique_size = subgroup_common.order
      return (self.G.degree / largest_clique_size)


    # need to determine how to reuse already-computed results
    # will be using a database to store computations

    def ub_no_homomorphism(self):
      min_int_dens = (self.G.order / 2)
      if not self.G.minimally_transitive:
        for id in self.G.minimally_transitive_subgroups:
          subgroup = TransitiveGroup(self.G.degree, id)
          sub_common = Common(subgroup)
          sub_ekr = EKR_Determiner(sub_common)
          if sub_ekr.has_ekr:
            return 1
          sub_int_dens = Intersection_Density(sub_common, sub_ekr)
          if sub_int_dens.upper_bound < min_int_dens:
            min_int_dens = sub_int_dens.upper_bound
      return min_int_dens

    def ub_ratio_bound(self):
      if self.has_ekr:
        return 1
      return self.G.degree / 1 + self.G.max_eigenvalue #max_wtd_evalue
      # line above this is just a placeholder until gurobi arrives

    def subgroup_by_non_derangements(self):
      non_derangements = [] # holds all non-derangement elements of G
      for c in self.G.conjugacy_classes: 
        if not Permutation(c.representative()).is_derangement():
          for element in c:
             non_derangements.append(element)
      return PermutationGroup(non_derangements)
     


