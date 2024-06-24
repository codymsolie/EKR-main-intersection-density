# Intersection Density.sage

# this file uses results from common and ekr_determiner to compute upper and lower bounds
# on the intersection density of a group, as well as an exact value if it is known.

import mariadb

class Intersection_Density:
    def __init__(self, G, ekr_determiner):
        self.G = G
        self.has_ekr = ekr_determiner.has_ekr
        self.max_wtd_eigenvalue = ekr_determiner.max_wtd_eigenvalue
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
        self.ub_ratio_bound() 
      ])

    def _get_lower_bound(self):
      if self.has_ekr:
        return 1
      if self.upper_bound == 1:
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
          print("\nnon derangement gives upper bound\n")
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
      return 1 # worst possible bound if nothing is found here

    def ub_clique_coclique(self):
      largest_clique_size = 2 #initializing to smallest clique size 
      for subgroup in self.G.subgroups:
        subgroup_common = Common(subgroup)
        if subgroup_common.min_eigenvalue == -1:
          if subgroup_common.max_eigenvalue == (subgroup_common.order - 1):
            if subgroup_common.order > largest_clique_size:
              largest_clique_size = subgroup_common.order
      print("Clique Coclique gives: ", self.G.degree/largest_clique_size)
      return (self.G.degree / largest_clique_size)

    def ub_no_homomorphism(self):
      min_int_dens = (self.G.order / 2)
      if not self.G.minimally_transitive:
        try:
          conn = mariadb.connect(
            user = "int_dens",
            password = "dbpass",
            host = "localhost",
            database = "intersection_density"
          )
          print("Connected to MariaDB!\n")
        except mariadb.Error as e:
          print(f"Error connecting to MariaDB platform: {e}")
          sys.exit(1)

        cursor = conn.cursor()

        for id in self.G.minimally_transitive_subgroups:
          cursor.execute(
          "SELECT (ekr,int_dens_hi) FROM Groups WHERE gap_id=? AND degree=?",
          (id, int(self.G.degree)))

          row = cursor.fetchone()

          if row[0]: # if group has EKR, we are done
            return 1

          if row[1] < min_int_dens:       # group does not have EKR, use int_dens_hi as new
            min_int_dens = cursor[0][1]   # lower bound if it improves the existing result
                                          

      print("No Homomorphism gives: ", min_int_dens)
      return min_int_dens

    def ub_ratio_bound(self):
      if self.max_wtd_eigenvalue:
        print("Ratio Bound gives: ", self.G.degree / (1 + int(round(self.max_wtd_eigenvalue))))
        return self.G.degree / (1 + int(round(self.max_wtd_eigenvalue)))
      return (self.G.order / 2)

    def subgroup_by_non_derangements(self):
      non_derangements = [] # holds all non-derangement elements of G
      for c in self.G.conjugacy_classes: 
        if not Permutation(c.representative()).is_derangement():
          for element in c:
             non_derangements.append(element)
      return PermutationGroup(non_derangements)
     
