class EKRM_Determiner:
    def __init__(self, G, ekr_determiner):
        self.G = G
        self.ekr_determiner = ekr_determiner
        self.has_ekrm = None
        self.reasons = []

        decomposition = self._get_permutation_decomposition()

        if G.n_cliques:
            if self._cliques_give_ekrm(decomposition):
                self.has_ekrm = True
                self.reasons.append("The group has an n-clique and every module not in the permutation representation contains a maximum coclique")
            if self._cocliques_disprove_ekrm(decomposition):
                self.has_ekrm = False
                self.reasons.append("The group has an n-clique and a maximum coclique sits in a module outside of the permutation representation")
        
        if not ekr_determiner.weightings is None:
            if self._weighted_eigenvalues_give_ekrm(decomposition):
                self.has_ekrm = True
                self.reasons.append("The only eigenvalues achieving minimum size with a weighting that gives EKR are the eigenvalues that correspond to characters in the permutation representation")
        
    
    def _cliques_give_ekrm(self, decomposition):
        cliques = self.G.n_cliques
        characters_not_in_permutation_representation = self._get_characters_not_in_decomposition(decomposition)

        for character in characters_not_in_permutation_representation:
            found_clique = False

            for clique in cliques:
                if self._get_character_sum(character, clique) != 0:
                    found_clique = True
                    break
            
            if not found_clique:
                return False
        
        return True

    def _cocliques_disprove_ekrm(self, decomposition):
        cocliques = self.G.stabilizer_sized_cocliques
        characters_not_in_permutation_representation = self._get_characters_not_in_decomposition(decomposition)

        for character in characters_not_in_permutation_representation:
            for coclique in cocliques:
                if self._get_character_sum(character, coclique) != 0:
                    return True

        return False

    def _weighted_eigenvalues_give_ekrm(self, decomposition, tolerance = 0.0001):
        derangement_classes = self.G.derangement_classes
        identity = self.G.identity
        characters = self.G.characters
        characters_in_permutation_representation = self._get_characters_in_decomposition(decomposition)

        weighted_eigenvalues = []
        for character in characters:
            eigenvalue_factor = 1/(character(identity))
            eigenvalue_sum = 0
            for (i, derangement_class) in enumerate(derangement_classes):
                representative = derangement_class[0]
                character_value = real(character(representative))
                eigenvalue_sum += self.ekr_determiner.weightings[i] * len(derangement_class) * float(character_value)
            
            eigenvalue = float(eigenvalue_factor) * eigenvalue_sum
            weighted_eigenvalues.append(eigenvalue)
        
        characters_with_eigenvalues_achieving_minimum = []
        for (i, eigenvalue) in enumerate(weighted_eigenvalues):
            if abs(eigenvalue - (-1)) < tolerance and not characters[i] in characters_in_permutation_representation:
                return False
            if abs(eigenvalue - (-1)) < tolerance:
                characters_with_eigenvalues_achieving_minimum.append(eigenvalue)
        
        if characters_with_eigenvalues_achieving_minimum == characters_in_permutation_representation:
            return True
        
        return False

    #Helper functions
    
    def _get_permutation_decomposition(self):
        characters = self.G.characters
        conjugacy_classes = self.G.conjugacy_classes
        order = self.G.order

        decomposition = []
        for character in characters:
            m_factor = 1/order
            m_sum = 0
            for conjugacy_class in conjugacy_classes:
                representative = conjugacy_class[0]
                fixed_points = Permutation(representative).fixed_points()
                character_value = character(representative)
                m_sum += len(conjugacy_class) * len(fixed_points) * character_value.conjugate()
            m_i = m_factor * m_sum
            decomposition.append(m_i)
        
        return decomposition
    
    def _get_characters_not_in_decomposition(self, decomposition):
        characters = self.G.characters

        characters_not_in_decomposition = []
        for (i, character) in enumerate(characters):
            if decomposition[i] == 0:
                characters_not_in_decomposition.append(character)
        
        return characters_not_in_decomposition


    def _get_characters_in_decomposition(self, decomposition):
        characters = self.G.characters

        characters_in_decomposition = []
        for (i, character) in enumerate(characters):
            if decomposition[i] != 0:
                characters_in_decomposition.append(character)
        
        return characters_in_decomposition
    

    def _get_character_sum(self, character, collection):
        character_sum = 0
        for g in collection:
            character_sum += character(g)
        
        return character_sum

