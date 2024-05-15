class Common:
    def __init__(self, group):
        self.group = group
        self.structure_description = gap.StructureDescription(group)
        self.degree = group.degree()
        self.order = group.order()
        self.transitivity = gap.Transitivity(group)
        self.identity = group.one()
        self.characters = group.irreducible_characters()
        self.minimally_transitive = self._get_minimally_transitive()
        self.conjugacy_classes = group.conjugacy_classes()
        self.derangement_classes = self._get_derangement_classes()
        self.subgroups = group.conjugacy_classes_subgroups()
        (self.eigenvalues, self.eigenvalues_with_multiplicities) = self._get_eigenvalues()
        self.max_eigenvalue = gap.Maximum(self.eigenvalues)
        self.min_eigenvalue = gap.Minimum(self.eigenvalues)
        self.n_cliques = self._get_n_cliques()
        self.stabilizer_sized_cocliques = self._get_stabilizer_sized_cocliques()
        self.larger_than_stabilizer_cocliques = self._get_larger_than_stabilizer_cocliques()
        self.minimally_transitive_subgroups = self._get_minimally_transitive_subgroups()
        self.is_a_join = self._get_is_a_join()
        self.is_a_complete_multipartite = self._get_is_a_complete_multipartite()
    
    def _get_derangement_classes(self):
        conjugacy_classes = self.conjugacy_classes

        derangement_classes = []
        for conjugacy_class in conjugacy_classes:
            representative = conjugacy_class[0]
            if not Permutation(representative).fixed_points():
                derangement_classes.append(conjugacy_class)
        
        return derangement_classes


    def _get_eigenvalues(self):
        characters = self.characters
        derangement_classes = self.derangement_classes
        identity = self.identity

        eigenvalues = []
        eigenvalues_with_multiplicities = []
        for character in characters:
            eigenvalue_sum = 0
            eigenvalue_factor = (1/character(identity))
            for derangement_class in derangement_classes:
                representative = derangement_class[0]
                character_value = character(representative)
                eigenvalue_sum += len(derangement_class) * character_value

            eigenvalue = eigenvalue_factor * eigenvalue_sum
            eigenvalues.append(eigenvalue)
            eigenvalues_with_multiplicities += [eigenvalue] * int((character(identity) ** 2)) #we have to cast to an int here in order to "multiply" the array

        return (eigenvalues, eigenvalues_with_multiplicities)


    def _get_n_cliques(self):                                    
        subgroups = self.subgroups
        n_subgroups = [subgroup for subgroup in subgroups if subgroup.order() == self.degree]

        n_cliques = []
        for subgroup in n_subgroups:
            eigenvalues = self._get_eigenvalues_subgroup(subgroup)
            minimum_eigenvalue = gap.Minimum(eigenvalues)

            if minimum_eigenvalue == -1:
                n_cliques.append(subgroup)

        return n_cliques


    def _get_stabilizer_sized_cocliques(self):
        subgroups = self.subgroups
        stabilizer_sized_subgroups = [subgroup for subgroup in subgroups if subgroup.order() == self.order/self.degree]

        stabilizer_sized_cocliques = []
        for subgroup in stabilizer_sized_subgroups:
            eigenvalues = self._get_eigenvalues_subgroup(subgroup)
            eigenvalue_is_zero = [eigenvalue == 0 for eigenvalue in eigenvalues]

            if all(eigenvalue_is_zero):
                stabilizer_sized_cocliques.append(subgroup)
        
        return stabilizer_sized_cocliques

    def _get_larger_than_stabilizer_cocliques(self):
        subgroups = self.subgroups
        larger_than_stabilizer_subgroups = [subgroup for subgroup in subgroups if subgroup.order() > self.order/self.degree]

        larger_than_stabilizer_cocliques = []
        for subgroup in larger_than_stabilizer_subgroups:
            eigenvalues = self._get_eigenvalues_subgroup(subgroup)
            eigenvalue_is_zero = [eigenvalue == 0 for eigenvalue in eigenvalues]

            if all(eigenvalue_is_zero):
                larger_than_stabilizer_cocliques.append(subgroup)
        
        return larger_than_stabilizer_cocliques

        # size of largest gives lower bound on int. density

    def _get_number(self):
        name = str(self.group)

        number_start_index = 24
        number = ""
        for char in name[number_start_index:]:
            if char.isdigit():
                number += char
            else:
                break
        
        return number

# check the index of the group against the list of minimally 
# transitive groups within its degree

    def _get_minimally_transitive(self):
        number = int(self._get_number())
        min_trans_list = gap.MinimalTransitiveIndices(int(self.degree))

        for index in min_trans_list:
            if number == index:
                return true
        return false


    #helper functions
    def _get_eigenvalues_subgroup(self, subgroup):
        characters = subgroup.irreducible_characters()
        conjugacy_classes = subgroup.conjugacy_classes()
        identity = subgroup.one()

        derangement_classes = []
        for conjugacy_class in conjugacy_classes:
            representative = conjugacy_class[0]
            if not Permutation(representative).fixed_points():
                derangement_classes.append(conjugacy_class)
        

        eigenvalues = []
        for character in characters:
            eigenvalue_sum = 0
            eigenvalue_factor = (1/character(identity))
            for derangement_class in derangement_classes:
                representative = derangement_class[0]
                character_value = character(representative)
                eigenvalue_sum += len(derangement_class) * character_value

            eigenvalue = eigenvalue_factor * eigenvalue_sum
            eigenvalues.append(eigenvalue)

        return eigenvalues

    def _get_minimally_transitive_subgroups(self):
        if (self.minimally_transitive):
            return []
        else:
            x = gap.MinimalTransitiveIndices(int(self.degree))
            minimal_transitive_subgroups = []

            for subgroup in self.subgroups:
                orbit_list = gap.Orbit(subgroup, 1)
                desired = list(range(1, self.degree + 1))

                if (desired == sorted(orbit_list)):
                    subgroup_index = gap.TransitiveIdentification(subgroup) #this line may take a severely long time to compute
                                                                            #and we are not entirely sure how long yet.
                    if (subgroup_index in x):
                        minimal_transitive_subgroups.append(subgroup_index)

            unique_min_trans = set(minimal_transitive_subgroups)
            minimal_transitive_subgroups = sorted(list(unique_min_trans))
        return minimal_transitive_subgroups


# this function tells us if the derangement graph is a join
    def _get_is_a_join(self):
        if (self.max_eigenvalue - self.min_eigenvalue) == self.order:
            return true
        return false

# this function tells us if the derangement graph is a complete multipartite
    def _get_is_a_complete_multipartite(self):
        if self.is_a_join:
            a = set(map(int, self.eigenvalues))
            b = set([int(self.max_eigenvalue), int(0), int(self.min_eigenvalue)])
            return a == b
        return false