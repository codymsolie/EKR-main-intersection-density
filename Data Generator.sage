import mariadb
import sys

class Data_Generator:
    def __init__(self, groups):

        groups_left = len(groups)
        for group in groups:
            try:
                print(f"{group}")
                print("Determing common properties")
                common = Common(group)
                print("Common properties determined")

                print("Determining EKR property")
                ekr = EKR_Determiner(common)
                print("EKR property determined")

                print("Determining EKR-module property")
                ekrm = EKRM_Determiner(common, ekr)
                print("EKR-module property determined")

                print("Determining strict EKR property")
                strict_ekr = Strict_EKR_Determiner(common, ekr, ekrm)
                print("Strict EKR property determined")

                print("Determining Intersection Density")
                intersection_density = Intersection_Density(common, ekr)
                print("Intersection Density determined")
        
                print("Saving data")
                data = {
                    "name": str(group),
                    "degree": common.degree,
                    "number": self._get_number(common),
                    "order": common.order,
                    "structure description": common.structure_description,
                    "intersection density upper": intersection_density.upper_bound,
                    "intersection density lower": intersection_density.lower_bound,
                    "intersection density exact": intersection_density.exact_value,
                    "transitivity": common.transitivity,
                    "minimally transitive": common.minimally_transitive,
                    "minimally transitive subgroups": common.minimally_transitive_subgroups,
                    "eigenvalues": self._get_nice_eigenvalues(common),
                    "is a join": common.is_a_join,
                    "is a complete multipartite": common.is_a_complete_multipartite,
                    "ekr": ekr.has_ekr,
                    "ekr reasons": ekr.reasons,
                    "ekrm": ekrm.has_ekrm,
                    "ekrm reasons": ekrm.reasons,
                    "sekr": strict_ekr.has_strict_ekr,
                    "sekr reasons": strict_ekr.reasons,
                    "abelian": group.is_abelian(),
                    "nilpotent": group.is_nilpotent(),
                    "primitive": group.is_primitive(),
                }

                self._save(data)
                print("Data saved")

                groups_left -= 1
                print(f"\n\n\nGroups left: {groups_left}")
        
            except Exception as e:
                print("ENCOUNTERED ERROR - CHECK errors.txt")
                error_log = open("errors.txt", "a")
                error_log.write(f"While checking the EKR properties of {group} we encountered the error {e}\n\n\n")
                error_log.close()

                skipped_log = open("skipped.txt", "a")
                skipped_log.write(f"{group}\n\n\n")
                skipped_log.close()

                groups_left -= 1

    def _get_number(self, common):
        name = str(common.group)

        number_start_index = 24
        number = ""
        for char in name[number_start_index:]:
            if char.isdigit():
                number += char
            else:
                break
        
        return number
    
    def _get_nice_eigenvalues(self, common):
        eigenvalues = common.eigenvalues
        unique_eigenvalues = set(eigenvalues)  #these two lines remove duplicate eigenvalues in the output
        eigenvalues = list(unique_eigenvalues)
        eigenvalues_with_multiplicities = common.eigenvalues_with_multiplicities

        eigenvalues_nice = []
        for eigenvalue in eigenvalues:
            eigenvalues_nice.append((int(eigenvalue), int(eigenvalues_with_multiplicities.count(eigenvalue))))
        eigenvalues_nice.sort()  #### must cast to int above so that values can be compared and sorted. 
        return eigenvalues_nice
    
    def _save(self, data):
        name = data["name"]
        degree = data["degree"]
        number = data["number"]
        order = data["order"]
        structure_description = data["structure description"]
        intersection_density_upper = data["intersection density upper"]
        intersection_density_lower = data["intersection density lower"]
        intersection_density_exact = data["intersection density exact"]
        transitivity = data["transitivity"]
        minimally_transitive = data["minimally transitive"]
        minimally_transitive_subgroups = data["minimally transitive subgroups"]
        eigenvalues = data["eigenvalues"]
        is_a_join = data["is a join"]
        is_a_complete_multipartite = data["is a complete multipartite"]
        ekr = data["ekr"] 
        ekr_reasons = data["ekr reasons"]
        ekrm = data["ekrm"]
        ekrm_reasons = data["ekrm reasons"]
        sekr = data["sekr"] 
        sekr_reasons = data["sekr reasons"]
        abelian = data["abelian"]
        nilpotent = data["nilpotent"]
        primitive = data["primitive"]

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

#### GROUP DB ####

        print("\nBEGINNING DATABASE QUERIES\n")
 
        cursor.execute(
          "SELECT group_id FROM Groups WHERE degree=? AND gap_id=?",
          (int(degree), int(number)))

        record_exists = cursor.rowcount

        if not record_exists:
          print("\nNEW GROUP TO INSERT\n")
          cursor.execute(
            "INSERT INTO Groups "\
            "(name,degree,gap_id,size,struc_desc"\
            ",int_dens_hi,int_dens_lo,int_dens,transitivity"\
            ",min_trans,is_join,is_cmp,ekr,ekrm,sekr"\
            ",is_abelian,is_nilpotent,is_primitive) VALUES "\
            "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
             (str(name), 
             int(degree), 
             int(number), 
             int(order), 
             str(structure_description),
             float(intersection_density_upper),
             float(intersection_density_lower),
             float(intersection_density_exact),
             int(transitivity),
             bool(minimally_transitive),
             bool(is_a_join),
             bool(is_a_complete_multipartite),
             bool(ekr),
             bool(ekrm),
             bool(sekr),
             bool(abelian),
             bool(nilpotent),
             bool(primitive))
          )
        else: 
          print("\nGROUP ALREADY EXISTS, UPDATE EXISTING\n")
          group_id = cursor.fetchone()[0]
          cursor.execute(
            "UPDATE Groups SET "\
            "name=?,"\
            "degree=?,"\
            "gap_id=?,"\
            "size=?,"\
            "struc_desc=?,"\
            "int_dens_hi=?,"\
            "int_dens_lo=?,"\
            "int_dens=?,"\
            "transitivity=?,"\
            "min_trans=?,"\
            "is_join=?,"\
            "is_cmp=?,"\
            "ekr=?,"\
            "ekrm=?,"\
            "sekr=?,"\
            "is_abelian=?,"\
            "is_nilpotent=?,"\
            "is_primitive=? "\
            "WHERE group_id=?",
             (str(name), 
             int(degree), 
             int(number), 
             int(order), 
             str(structure_description),
             float(intersection_density_upper),
             float(intersection_density_lower),
             float(intersection_density_exact),
             int(transitivity),
             bool(minimally_transitive),
             bool(is_a_join),
             bool(is_a_complete_multipartite),
             bool(ekr),
             bool(ekrm),
             bool(sekr),
             bool(abelian),
             bool(nilpotent),
             bool(primitive),
             group_id))

        conn.commit()

        print("\nFINISHED SAVING GROUP PROPERTIES\n")

        cursor.execute("SELECT group_id FROM Groups WHERE gap_id=? AND degree=?",
                       (int(number), int(degree))) 

        group_id = cursor.fetchone()[0]

        print("\nGROUP_ID: ", group_id, "\n")

##### MINIMALLY TRANSITIVE SUBGROUPS DB ####

        print("\nBEGINNING SUBGROUP QUERIES\n")

        cursor.execute(
          "SELECT subgroup_id FROM Subgroups WHERE group_id=?",
          [group_id]) # checks to see if records for this group already exist

        records_exist = cursor.rowcount

        print("\nMINIMALLY TRANSITIVE: ", minimally_transitive, "\n")

        if not records_exist:
          print("\nNEW SUBGROUPS\n")
          for subgroup in minimally_transitive_subgroups:
            cursor.execute(
              "INSERT INTO Subgroups (group_id,degree,gap_id) VALUES (?, ?, ?)",
              (group_id,int(degree),int(subgroup)))
          conn.commit()

        print("\nFINISHED SUBGROUP QUERIES\n")

#### EIGENVALUES DB ####

        print("\nBEGINNING EIGENVALUE QUERIES\n")

        cursor.execute(
          "SELECT evalue_id FROM Eigenvalues WHERE group_id=?",
          [group_id]) # checks to see if records for this group already exist

        records_exist = cursor.rowcount

        if not records_exist:
          print("\nNEW EIGENVALUES\n")
          for pair in eigenvalues:
            cursor.execute(
              "INSERT INTO Eigenvalues (group_id, eigenvalue, multiplicity) VALUES (?, ?, ?)",
              (group_id, int(pair[0]), int(pair[1])))
            conn.commit()
        
        print("\nFINISHED EVALUES\n")
        conn.close()
