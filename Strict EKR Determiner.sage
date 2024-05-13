import numpy as np

class Strict_EKR_Determiner:
    def __init__(self, G, ekr_determiner, ekrm_determiner):
        self.G = G
        self.has_strict_ekr = None
        self.reasons = []

        if not ekr_determiner.has_ekr:
            self.has_strict_ekr = False
            self.reasons.append("Group does not have the EKR property")
        if not ekrm_determiner.has_ekrm and not ekrm_determiner.has_ekrm is None:  #??????
            self.has_strict_ekr = False
            self.reasons.append("Group does not have the EKRM property")
        
        if self.has_strict_ekr is None:
            if G.transitivity >=2 and self._module_method_gives_sekr():
                self.has_strict_ekr = True
                self.reasons.append("Group is two transitive and gets strict EKR from the module method")

                ekrm_determiner.has_ekrm = True
                ekrm_determiner.reasons.append("Group has the strict EKR property")

            else:
                if self._coclique_disproves_sekr():
                    self.has_strict_ekr = False
                    self.reasons.append("There is a coclique of size |G|/n that is not the stabilizer of a point or a coset of one")


    def _module_method_gives_sekr(self):        
        m_matrix = self._get_m_matrix()
        n_matrix = self._get_n_matrix(m_matrix)
        n_matrix_rank = self._get_matrix_rank(n_matrix)

        if n_matrix_rank == (self.G.degree - 1) * (self.G.degree - 2):
            return True
        else:
            return False

    def _coclique_disproves_sekr(self):
        stabilizer_sized_cocliques = self.G.stabilizer_sized_cocliques
        
        for coclique in stabilizer_sized_cocliques:
            if not self._collection_is_the_stabilizer_of_a_point(coclique):
                return True
        
        return False
    

    #helper functions
    def _get_m_matrix(self):
        m_rows = []
        degree = self.G.degree
        order = self.G.order

        for g in self.G.group:
            m_row = []

            for i in range(1,degree + 1):
                m_sub_row = [0] * degree 
                j = g(i)
                m_sub_row[j - 1] = 1
                m_row += m_sub_row

            m_rows += m_row

        m_matrix = (np.array(m_rows))
        m_matrix.shape = (order, degree*degree)

        return m_matrix

    def _get_n_matrix(self, m_matrix):
        degree = self.G.degree
        order = self.G.order

        h = []
        for i in range(1, degree + 1):
            for j in range(1, degree + 1):
                if(i != j and i!=degree and j!=degree):
                    column_number = (i-1)*degree + j
                    column = m_matrix[:, column_number - 1]
                    h.append(column)

        H = np.column_stack(h)

        n_matrix_rows = []

        for i in range(0, order):
            if not Permutation(self.G.group[i]).fixed_points():
                n_matrix_rows.append(H[i])

        n_matrix = np.array(n_matrix_rows)

        derangement_classes = self.G.derangement_classes
        number_of_derangments = 0
        for derangement_class in derangement_classes:
            number_of_derangments += len(derangement_class)

        n_matrix.shape = (number_of_derangments, (degree - 1) * (degree - 2))

        return n_matrix

    def _get_matrix_rank(self, matrix):
        rank = np.linalg.matrix_rank(matrix)
        return rank

    def _collection_is_the_stabilizer_of_a_point(self, collection):
        for i in range(1, self.G.degree + 1):
            if collection == self.G.group.stabilizer(i):
                return True
        return False

    