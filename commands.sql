/* B- Création des TableSpaces et utilisateur*/
/*2. Créer deux TableSpaces SQL3_TBS et SQL3_TempTBS*/
  
create tablespace SQL3_TBS datafile 'c:\sql3_tbs.dat' size 100M autoextend on online;
create temporary tablespace SQL3_TempTBS tempfile 'c:\sql3_temptbs.dat' size 100M autoextend on;

/* 1. Créer un utilisateur SQL3 en lui attribuant les deux tablespaces créés précédemment*/

create user sql3 identified by psw default tablespace SQL3_TBS temporary tablespace SQL3_TempTBS;

/* 1. Donner tous les privilèges à cet utilisateur.*/

grant all privileges to sql3;

/*C- Langage de définition de données*/
/*5. En se basant sur le diagramme de classes fait, définir tous les types nécessaires. Prendre en compte toutes les associations qui existent.*/

create type Tinterventions;
/
create type Temploye;
/
create type Tvehicule;
/
create type Tclient;
/
create type Tmodele;
/
create type Tmarque;
/

create or replace type Tintervenants as object (
NUMINTERVENTION ref Tinterventions,
NUMEMPLOYE ref Temploye,
DATEDEBUT DATE,
DATEFIN DATE
);
/

create type tset_intervenants as table of ref Tintervenants;
/

create or replace type Temploye as object(
NUMEMPLOYE number,
NOMEMP varchar2(20),
PRENOMEMP varchar2(20),
CATEGORIE varchar2(20),
SALAIRE float,
EMPLOYE_INTERVENANTS tset_intervenants
);
/

create type tset_employes as table of ref Temploye;
/

create or replace type Tinterventions as object(
NUMINTERVENTION number,
NUMVEHICULE ref Tvehicule,
TYPEINTERVENTION varchar2(20),
DATEDEBINTERV date,
DATEFININTERV date,
COUTINTERV float,
INTERVENTION_INTERVENANTS tset_intervenants,
INTERVENTION_EMPLOYES tset_employes
);
/

create type tset_interventions as table of ref Tinterventions;
/

alter type Temploye add attribute EMPLOYE_INTERVENTIONS tset_interventions cascade;

create or replace type Tvehicule as object(
NUMVEHICULE number,
NUMCLIENT ref Tclient,
NUMMODELE ref Tmodele,
NUMIMMAT VARCHAR2(20),
ANNEE NUMBER,
VEHICULE_INTERVENTIONS tset_interventions
);
/

create type tset_vehicules as table of ref Tvehicule;
/

create or replace type Tclient as object(
NUMCLIENT number,
CIV varchar2(3),
PRENOMCLIENT varchar2(20),
NOMCLIENT varchar2(20),
DATENAISSANCE date,
ADRESSE varchar2(100),
TELPROF varchar2(20),
TELPRIV varchar2(20),
FAX varchar2(20),
CLIENT_VEHICULES tset_vehicules
);
/

create or replace type Tmodele as object (
NUMMODELE NUMBER,
NUMMARQUE ref Tmarque,
MODELE varchar2(20),
MODELE_VEHICULES tset_vehicules
);
/

create type tset_modeles as table of ref Tmodele;
/

create or replace type Tmarque as object (
NUMMARQUE number,
MARQUE varchar2(20),
PAYS  varchar2(20),
MARQUE_MODELES tset_modeles
);
/

/*6. Définir les méthodes permettant de :*/

/*calculer pour chaque employe, le nombre d'interventions effectuées*/
alter type Temploye add member function nb_interventions return number cascade;
CREATE OR REPLACE TYPE BODY Temploye AS
  MEMBER FUNCTION nb_interventions RETURN NUMBER IS
    total_interventions NUMBER := 0;
  BEGIN
    RETURN self.EMPLOYE_INTERVENTIONS.COUNT;
  END;
END;
/

/*calculer pour chaque marque le nombre de modèles*/
alter type Tmarque add member function nb_modeles return number cascade;

CREATE OR REPLACE TYPE BODY Tmarque AS
    MEMBER FUNCTION nb_modeles RETURN NUMBER IS
    BEGIN
        RETURN self.MARQUE_MODELES.COUNT;
    END nb_modeles;
END;
/

 
 /*calculer pour chaque modele, le nombre de véhicules*/
alter type Tmodele add member function nb_vehicules return number cascade;
CREATE OR REPLACE TYPE BODY Tmodele AS
    MEMBER FUNCTION nb_vehicules RETURN NUMBER IS
    BEGIN
        RETURN self.MODELE_VEHICULES.COUNT;
    END nb_vehicules;
END;
/
 
 /*lister pour chaque client, ses véhicules*/
create type tliste_vehicules as table of Tvehicule;
 alter type Tclient add member function lister_vehicules return tliste_vehicules cascade;
 CREATE OR REPLACE TYPE BODY Tclient AS
  member function lister_vehicules return tliste_vehicules IS
    liste_v tliste_vehicules;
  BEGIN
    Select CAST(MULTISET( select deref(value(v))
                      from table(self.CLIENT_VEHICULES) v) as tliste_vehicules
		   ) into liste_v from dual; 
    return liste_v;
  END lister_vehicules;
END;
/
/*calculer pour chaque marque, son chiffre d'affaire*/
alter type Tmarque add member function chiffre_affaire return number cascade;
create or replace type body Tmarque as
  member function chiffre_affaire return number is
    ca number;
  BEGIN
    Select CAST(MULTISET( select sum(deref(deref(deref(value(m)).MODELE_VEHICULES).VEHICULE_INTERVENTIONS).COUTINTERV)
                      from table(self.MARQUE_MODELES) m
                     ) as number
		   ) into ca from dual; 
	  END chiffre_affaire;
	END;
	/


/* 7. Définir les tables nécessaires à la base de données.*/
-- Création de la table pour le type Tmarque
CREATE TABLE Marques OF Tmarque (
   constraint pk_marques primary key(NUMMARQUE)
) NESTED TABLE MARQUE_MODELES STORE AS marque_modeles_table;

-- Création de la table pour le type Tmodele  
CREATE TABLE Modeles OF Tmodele (
   constraint pk_modeles primary key(NUMMODELE)
) NESTED TABLE MODELE_VEHICULES STORE AS modele_vehicules_table;

-- Création de la table pour le type Tclient
CREATE TABLE Clients OF Tclient (
   CONSTRAINT pk_clients PRIMARY KEY (NUMCLIENT),
   CONSTRAINT check_civ_client CHECK (CIV IN ('M', 'Mle', 'Mme'))
)
NESTED TABLE CLIENT_VEHICULES STORE AS client_vehicules_table;

-- Création de la table pour le type Tvehicule
CREATE TABLE Vehicules OF Tvehicule (
    constraint pk_vehicules primary key(NUMVEHICULE)
) NESTED TABLE VEHICULE_INTERVENTIONS STORE AS vehicule_interventions_table;

-- Création de la table pour le type Temploye
CREATE TABLE Employes OF Temploye (
   CONSTRAINT pk_employes PRIMARY KEY (NUMEMPLOYE),
   CONSTRAINT check_categorie_employe CHECK (CATEGORIE IN ('Mécanicien', 'Assistant'))
)
NESTED TABLE EMPLOYE_INTERVENANTS STORE AS employe_intervenants_table,
NESTED TABLE EMPLOYE_INTERVENTIONS STORE AS employe_interventions_table;



-- Création de la table pour le type Tinterventions  
CREATE TABLE Interventions OF Tinterventions (
    constraint pk_interventions primary key(NUMINTERVENTION)
) NESTED TABLE INTERVENTION_INTERVENANTS STORE AS intervention_intervenant_table
  NESTED TABLE INTERVENTION_EMPLOYES STORE AS intervention_employes_table;

-- Création de la table pour le type Tintervenants 
CREATE TABLE Intervenants OF Tintervenants ;

/*LES INSERTIONS*/
alter session set nls_date_format = 'DD/MM/RRRR HH24:MI:SS';
--table Clients
INSERT INTO Clients VALUES (1,'Mme','Cherifa','MAHBOUBA','08/08/1957','CITE 1013 LOGTS BT 61 Alger','0561381813','0562458714','', tset_vehicules());
INSERT INTO Clients VALUES (2,'Mme','Lamia','TAHMI','31/12/1955','CITE BACHEDJARAH BATIMENT 38 -Bach Djerrah-Alger','0562467849','0561392487','', tset_vehicules());
INSERT INTO Clients VALUES (3,'Mle','Ghania','DIAF AMROUNI','31/12/1955','43, RUE ABDERRAHMANE SBAA BELLE VUE-EL HARRACH-ALGER','0523894562','0619430945','0562784254', tset_vehicules());
INSERT INTO Clients VALUES (4,'Mle','Chahinaz','MELEK','27/06/1955','HLM AISSAT IDIR CAGE 9 3EME ETAGE-EL HARRACH ALGER','0634613493','0562529463','', tset_vehicules());
INSERT INTO Clients VALUES (5,'Mme','Noura','TECHTACHE','22/03/1949','16, ROUTE EL DJAMILA-AINBENIAN-ALGER','0562757834','','0562757843', tset_vehicules());
INSERT INTO Clients VALUES (6,'Mme','Widad','TOUATI','14/08/1965','14 RUE DES FRERES AOUDIA-EL MOURADIA-ALGER','0561243967','0561401836','', tset_vehicules());
INSERT INTO Clients VALUES (7,'Mle','Faiza','ABLOUL','28/10/1967','CITE DIPLOMATIQUE BT BLEU 14B N 3 DERGANA- ALGER','0562935427','0561486203','', tset_vehicules());
INSERT INTO Clients VALUES (8,'Mme','Assia','HORRA','08/12/1963','32 RUE AHMED OUAKED-DELY BRAHIM-ALGER','0561038500','','0562466733', tset_vehicules());
INSERT INTO Clients VALUES (9,'Mle','Souad','MESBAH','30/08/1972','RESIDENCE CHABANI-HYDRA-ALGER','0561024358','','', tset_vehicules());
INSERT INTO Clients VALUES (10,'Mme','Houda','GROUDA','20/02/1950','EPSP THNIET ELABED BATNA','0562939495','0561218456','', tset_vehicules());
INSERT INTO Clients VALUES (11,'Mle','Saida','FENNICHE','','CITE DE L''INDEPENDANCE LARBAA BLIDA','0645983165','0562014784','', tset_vehicules());
INSERT INTO Clients VALUES (12,'Mme','Samia','OUALI','17/11/1966','CITE 200 LOGEMENTS BT1 N1-JIJEL','0561374812','0561277013','', tset_vehicules());
INSERT INTO Clients VALUES (13,'Mme','Fatiha','HADDAD','20/09/1980','RUE BOUFADA LAKHDARAT-AIN OULMANE-SETIF','0647092453','0562442700','', tset_vehicules());
INSERT INTO Clients VALUES (14,'M.','Djamel','MATI','','DRAA KEBILA HAMMAM GUERGOUR SETIF','0561033663','0561484259','', tset_vehicules());
INSERT INTO Clients VALUES (15,'M.','Mohamed','GHRAIR','24/06/1950','CITE JEANNE D''ARC ECRAN B5- GAMBETTA – ORAN','0561390288','','0562375849', tset_vehicules());
INSERT INTO Clients VALUES (16,'M.','Ali','LAAOUAR','','CITE 1ER MAI EX 137 LOGEMENTS-ADRAR','0639939410','0561255412','', tset_vehicules());
INSERT INTO Clients VALUES (17,'M.','Messoud','AOUIZ','24/11/1958','RUE SAIDANI ABDESSLAM -AIN BESSEM-BOUIRA','0561439256','0561473625','', tset_vehicules());
INSERT INTO Clients VALUES (18,'M.','Farid','AKIL','06/05/1961','3 RUE LARBI BEN M''HIDI-DRAA EL MIZAN-TIZI OUZOU','0562349254','0561294268','', tset_vehicules());
INSERT INTO Clients VALUES (19,'Mme','Dalila','MOUHTADI','','6, BD TRIPOLI ORAN','0506271459','0506294186','', tset_vehicules());
INSERT INTO Clients VALUES (20,'M.','Younes','CHALAH','','CITE DES 60 LOGTS BT D N 48- NACIRIA-BOUMERDES','','0561358279','', tset_vehicules());
INSERT INTO Clients VALUES (21,'M.','Boubeker','BARKAT','08/11/1935','CITE MENTOURI N 71 BT AB SMK Constantine','0561824538','0561326179','', tset_vehicules());
INSERT INTO Clients VALUES (22,'M.','Seddik','HMIA','','25 RUE BEN YAHIYA-JIJEL','0562379513','','0562493627', tset_vehicules());
INSERT INTO Clients VALUES (23,'M.','Lamine','MERABAT','09/13/1965','CITE JEANNE D''ARC ECRAN B2-GAMBETTA – ORAN','0561724538','0561724538','', tset_vehicules());

--table Employes
INSERT INTO Employes VALUES(53,'LACHEMI','Bouzid','Mécanicien',25000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(54,'BOUCHEMLA','Elias','Assistant',10000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(55,'HADJ','Zouhir','Assistant',12000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(56,'OUSSEDIK','Hakim','Mécanicien',20000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(57,'ABAD','Abdelhamid','Assistant',13000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(58,'BABACI','Tayeb','Mécanicien',21300, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(59,'BELHAMIDI','Mourad','Mécanicien',19500, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(60,'IGOUDJIL','Redouane','Assistant',15000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(61,'KOULA','Bahim','Mécanicien',23100, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(62,'RAHALI','Ahcene','Mécanicien',24000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(63,'CHAOUI','Ismail','Assistant',13000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(64,'BADI','Hatem','Assistant',14000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(65,'MOHAMMEDI','Mustapha','Mécanicien',24000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(66,'FEKAR','Abdelaziz','Assistant',13500, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(67,'SAIDOUNI','Wahid','Mécanicien',25000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(68,'BOULARAS','Farid','Assistant',14000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(69,'CHAKER','Nassim','Mécanicien',26000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(71,'TERKI','Yacine','Mécanicien',23000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(72,'TEBIBEL','Ahmed','Assistant',17000, tset_intervenants(), tset_interventions());
INSERT INTO Employes VALUES(80,'LARDJOUNE','Karim','',25000, tset_intervenants(), tset_interventions());

--table marques 
-- Insertions pour la table Marques
INSERT INTO Marques VALUES (Tmarque(1, 'LAMBORGHINI', 'ITALIE', tset_modeles()));
INSERT INTO Marques VALUES ( Tmarque(2, 'AUDI', 'ALLEMAGNE', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(3, 'ROLLS-ROYCE', 'GRANDE-BRETAGNE', tset_modeles()));
INSERT INTO Marques VALUES ( Tmarque(4, 'BMW', 'ALLEMAGNE', tset_modeles()));
INSERT INTO Marques VALUES ( Tmarque(5, 'CADILLAC', 'ETATS-UNIS', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(6, 'CHRYSLER', 'ETATS-UNIS', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(7, 'FERRARI', 'ITALIE', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(8, 'HONDA', 'JAPON', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(9, 'JAGUAR', 'GRANDE-BRETAGNE', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(10, 'ALFA-ROMEO', 'ITALIE', tset_modeles()));
INSERT INTO Marques VALUES ( Tmarque(11, 'LEXUS', 'JAPON', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(12, 'LOTUS', 'GRANDE-BRETAGNE', tset_modeles()));
INSERT INTO Marques VALUES ( Tmarque(13, 'MASERATI', 'ITALIE', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(14, 'MERCEDES', 'ALLEMAGNE', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(15, 'PEUGEOT', 'FRANCE', tset_modeles()));
INSERT INTO Marques VALUES ( Tmarque(16, 'PORSCHE', 'ALLEMAGNE', tset_modeles()));
INSERT INTO Marques VALUES ( Tmarque(17, 'RENAULT', 'FRANCE', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(18, 'SAAB', 'SUEDE', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(19, 'TOYOTA', 'JAPON', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(20, 'VENTURI', 'FRANCE', tset_modeles()));
INSERT INTO Marques VALUES (Tmarque(21, 'VOLVO', 'SUEDE', tset_modeles()));

--tables modeles
-- Insertions pour la table MODELE
INSERT INTO Modeles VALUES ( Tmodele(2, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 1), 'Diablo', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(3, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 2), 'Serie 5', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(4, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 10), 'NSX', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(5, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 14), 'Classe C', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(6, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 17), 'Safrane', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(7, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 20), '400 GT', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(8, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 12), 'Esprit', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(9, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 15), '605', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(10, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 19), 'Previa', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(11, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 7), '550 Maranello', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(12, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 3), 'Bentley-Continental', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(13, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 10), 'Spider', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(14, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 13), 'Evoluzione', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(15, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 16), 'Carrera', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(16, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 16), 'Boxter', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(17, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 21), 'S 80', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(18, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 6), '300 M', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(19, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 4), 'M 3', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(20, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 9), 'XJ 8', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(21, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 15), '406 Coupe', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(22, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 20), '300 Atlantic', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(23, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 14), 'Classe E', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(24, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 11), 'GS 300', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(25, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 5), 'Seville', tset_vehicules()));
INSERT INTO Modeles VALUES ( Tmodele(26, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 18), '95 Cabriolet', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(27, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 2), 'TT Coupé', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(28, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 7), 'F 355', tset_vehicules()));
INSERT INTO Modeles VALUES (Tmodele(29, (SELECT REF(m) FROM Marques m WHERE m.NUMMARQUE = 45), 'POLO', tset_vehicules()));

--tables vehicules
INSERT INTO Vehicules VALUES(1,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 2),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 6),'0012519216',1992,tset_interventions());
INSERT INTO Vehicules VALUES(2,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 9),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 20),'0124219316',1993,tset_interventions());
INSERT INTO Vehicules VALUES(3,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 17),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 8),'1452318716',1987,tset_interventions());
INSERT INTO Vehicules VALUES(4,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 6),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 12),'3145219816',1998,tset_interventions());
INSERT INTO Vehicules VALUES(5,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 16),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 23),'1278919816',1998,tset_interventions());
INSERT INTO Vehicules VALUES(6,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 20),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 6),'3853319735',1997,tset_interventions());
INSERT INTO Vehicules VALUES(7,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 7),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 8),'1453119816',1998,tset_interventions());
INSERT INTO Vehicules VALUES(8,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 16),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 14),'8365318601',1986,tset_interventions());
INSERT INTO Vehicules VALUES(9,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 13),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 15),'3087319233',1992,tset_interventions());
INSERT INTO Vehicules VALUES(10,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 20),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 22),'9413119935',1999,tset_interventions());
INSERT INTO Vehicules VALUES(11,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 9),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 16),'1572319801',1998,tset_interventions());
INSERT INTO Vehicules VALUES(12,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 14),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 20),'6025319733',1997,tset_interventions());
INSERT INTO Vehicules VALUES(13,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 19),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 17),'5205319736',1997,tset_interventions());
INSERT INTO Vehicules VALUES(14,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 22),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 21),'7543119207',1992,tset_interventions());
INSERT INTO Vehicules VALUES(15,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 4),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 19),'6254319916',1999,tset_interventions());
INSERT INTO Vehicules VALUES(16,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 16),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 21),'9831419701',1997,tset_interventions());
INSERT INTO Vehicules VALUES(17,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 12),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 11),'4563117607',1976,tset_interventions());
INSERT INTO Vehicules VALUES(18,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 1),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 2),'7973318216',1982,tset_interventions());
INSERT INTO Vehicules VALUES(19,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 18),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 77),'3904318515',1985,tset_interventions());
INSERT INTO Vehicules VALUES(20,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 22),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 2),'1234319707',1997,tset_interventions());
INSERT INTO Vehicules VALUES(21,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 3),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 19),'8429318516',1985,tset_interventions());
INSERT INTO Vehicules VALUES(22,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 8),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 19),'1245619816',1998,tset_interventions());
INSERT INTO Vehicules VALUES(23,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 7),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 25),'1678918516',1985,tset_interventions());
INSERT INTO Vehicules VALUES(24,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 80),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 9),'1789519816',1998,tset_interventions());
INSERT INTO Vehicules VALUES(25,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 13),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 5),'1278919833',1998,tset_interventions());
INSERT INTO Vehicules VALUES(26,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 3),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 10),'1458919316',1993,tset_interventions());
INSERT INTO Vehicules VALUES(27,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 10),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 7),'1256019804',1998,tset_interventions());
INSERT INTO Vehicules VALUES(28,(SELECT REF(c) FROM Clients c WHERE c.NUMCLIENT = 10),(SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 3),'1986219904',1999,tset_interventions());

--table interventions
INSERT INTO Interventions  VALUES(1,(select ref(v) from Vehicules v where v.NUMVEHICULE=3),'Réparation',TO_DATE('2006-02-25 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-26 12:00:00','RRRR-MM-DD HH24:MI:SS'),30000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(2,(select ref(v) from Vehicules v where v.NUMVEHICULE=21),'Réparation',TO_DATE('2006-02-23 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-24 18:00:00','RRRR-MM-DD HH24:MI:SS'),10000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(3,(select ref(v) from Vehicules v where v.NUMVEHICULE=25),'Réparation',TO_DATE('2006-04-06 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-04-09 12:00:00','RRRR-MM-DD HH24:MI:SS'),42000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(4,(select ref(v) from Vehicules v where v.NUMVEHICULE=10),'Entretien',TO_DATE('2006-05-14 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-14 18:00:00','RRRR-MM-DD HH24:MI:SS'),10000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(5,(select ref(v) from Vehicules v where v.NUMVEHICULE=6),'Réparation',TO_DATE('2006-02-22 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-25 18:00:00','RRRR-MM-DD HH24:MI:SS'),40000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(6,(select ref(v) from Vehicules v where v.NUMVEHICULE=14),'Entretien',TO_DATE('2006-03-03 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-03-04 18:00:00','RRRR-MM-DD HH24:MI:SS'),7500, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(7,(select ref(v) from Vehicules v where v.NUMVEHICULE=1),'Entretien',TO_DATE('2006-04-09 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-04-09 18:00:00','RRRR-MM-DD HH24:MI:SS'),8000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(8,(select ref(v) from Vehicules v where v.NUMVEHICULE=17),'Entretien',TO_DATE('2006-05-11 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-12 18:00:00','RRRR-MM-DD HH24:MI:SS'),9000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(9,(select ref(v) from Vehicules v where v.NUMVEHICULE=22),'Entretien',TO_DATE('2006-02-22 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-22 18:00:00','RRRR-MM-DD HH24:MI:SS'),7960, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(10,(select ref(v) from Vehicules v where v.NUMVEHICULE=2),'Entretien et Reparation',TO_DATE('2006-04-08 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-04-09 18:00:00','RRRR-MM-DD HH24:MI:SS'),45000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(11,(select ref(v) from Vehicules v where v.NUMVEHICULE=28),'Réparation',TO_DATE('2006-03-08 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-03-17 12:00:00','RRRR-MM-DD HH:MI:SS'),36000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(12,(select ref(v) from Vehicules v where v.NUMVEHICULE=20),'Entretien et Reparation',TO_DATE('2006-05-03 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-05 18:00:00','RRRR-MM-DD HH24:MI:SS'),27000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(13,(select ref(v) from Vehicules v where v.NUMVEHICULE=8),'Réparation Systeme',TO_DATE('2006-05-12 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-12 18:00:00','RRRR-MM-DD HH24:MI:SS'),17846, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(14,(select ref(v) from Vehicules v where v.NUMVEHICULE=1),'Réparation',TO_DATE('2006-05-10 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-12 12:00:00','RRRR-MM-DD HH24:MI:SS'),39000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(15,(select ref(v) from Vehicules v where v.NUMVEHICULE=20),'Réparation Systeme',TO_DATE('2006-06-25 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-06-25 12:00:00','RRRR-MM-DD HH24:MI:SS'),27000, tset_intervenants(), tset_employes());
INSERT INTO Interventions  VALUES(16,(select ref(v) from Vehicules v where v.NUMVEHICULE=77),'Réparation',TO_DATE('2006-06-27 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-06-30 12:00:00','RRRR-MM-DD HH24:MI:SS'),25000, tset_intervenants(), tset_employes());

--table intervenants
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=1),(select ref(e) from Employes e where e.NUMEMPLOYE=54),To_DATE('2006-02-26 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-26 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=1),(select ref(e) from Employes e where e.NUMEMPLOYE=59),TO_DATE('2006-02-25 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-25 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=2),(select ref(e) from Employes e where e.NUMEMPLOYE=57),TO_DATE('2006-02-24 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-24 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=2),(select ref(e) from Employes e where e.NUMEMPLOYE=59),TO_DATE('2006-02-23 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-24 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=3),(select ref(e) from Employes e where e.NUMEMPLOYE=60),TO_DATE('2006-04-09 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-04-09 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=3),(select ref(e) from Employes e where e.NUMEMPLOYE=65),TO_DATE('2006-04-06 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-04-08 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=4),(select ref(e) from Employes e where e.NUMEMPLOYE=62),TO_DATE('2006-05-14 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-14 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=4),(select ref(e) from Employes e where e.NUMEMPLOYE=66),TO_DATE('2006-02-14 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-14 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=5),(select ref(e) from Employes e where e.NUMEMPLOYE=56),TO_DATE('2006-02-22 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-25 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=5),(select ref(e) from Employes e where e.NUMEMPLOYE=60),TO_DATE('2006-02-23 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-25 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=6),(select ref(e) from Employes e where e.NUMEMPLOYE=53),TO_DATE('2006-03-03 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-03-04 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=6),(select ref(e) from Employes e where e.NUMEMPLOYE=57),TO_DATE('2006-03-04 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-03-04 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=7),(select ref(e) from Employes e where e.NUMEMPLOYE=55),TO_DATE('2006-04-09 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-04-09 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=7),(select ref(e) from Employes e where e.NUMEMPLOYE=65),TO_DATE('2006-04-09 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-04-09 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=8),(select ref(e) from Employes e where e.NUMEMPLOYE=54),TO_DATE('2006-05-12 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-12 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=8),(select ref(e) from Employes e where e.NUMEMPLOYE=62),TO_DATE('2006-05-11 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-12 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=9),(select ref(e) from Employes e where e.NUMEMPLOYE=59),TO_DATE('2006-02-22 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-22 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=9),(select ref(e) from Employes e where e.NUMEMPLOYE=60),TO_DATE('2006-02-22 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-02-22 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=10),(select ref(e) from Employes e where e.NUMEMPLOYE=63),TO_DATE('2006-04-09 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-04-09 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=10),(select ref(e) from Employes e where e.NUMEMPLOYE=67),TO_DATE('2006-04-08 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-04-09 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=11),(select ref(e) from Employes e where e.NUMEMPLOYE=59),TO_DATE('2006-03-09 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-03-11 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=11),(select ref(e) from Employes e where e.NUMEMPLOYE=64),TO_DATE('2006-03-09 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-03-17 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=11),(select ref(e) from Employes e where e.NUMEMPLOYE=53),TO_DATE('2006-03-08 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-03-16 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=12),(select ref(e) from Employes e where e.NUMEMPLOYE=55),TO_DATE('2006-05-05 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-05 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=12),(select ref(e) from Employes e where e.NUMEMPLOYE=56),TO_DATE('2006-05-03 09:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-05 12:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=13),(select ref(e) from Employes e where e.NUMEMPLOYE=64),TO_DATE('2006-05-12 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-12 18:00:00','RRRR-MM-DD HH24:MI:SS'));
INSERT INTO INTERVENANTS  VALUES((select ref(i) from Interventions i where i.NUMINTERVENTION=14),(select ref(e) from Employes e where e.NUMEMPLOYE=88),TO_DATE('2006-05-07 14:00:00','RRRR-MM-DD HH24:MI:SS'),TO_DATE('2006-05-10 18:00:00','RRRR-MM-DD HH24:MI:SS'));

/*INSERTION DES TABLES IMBRIQUEES*/

/*CLIENT_VEHICULES*/
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=1) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=1));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=2) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=2));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=3) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=3));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=4) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=4));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=5) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=5));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=6) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=6));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=7) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=7));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=8) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=8));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=9) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=9));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=10) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=10));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=11) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=11));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=12) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=12));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=13) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=13));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=14) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=14));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=15) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=15));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=16) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=16));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=17) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=17));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=18) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=18));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=19) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=19));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=20) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=20));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=21) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=21));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=22) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=22));
insert into table(select c.CLIENT_VEHICULES from Clients c where c.NUMCLIENT=23) (select ref(v) from Vehicules v where v.NUMCLIENT=(select ref(c) from Clients c where c.NUMCLIENT=23));

/*EMPLOYE_INTERVENANTS*/
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=53) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=53));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=54) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=54));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=55) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=55));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=56) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=56));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=57) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=57));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=58) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=58));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=59) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=59));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=60) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=60));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=61) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=61));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=62) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=62));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=63) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=63));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=64) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=64));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=65) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=65));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=66) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=66));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=67) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=67));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=68) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=68));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=69) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=69));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=71) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=71));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=72) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=72));
insert into table(select e.EMPLOYE_INTERVENANTS from Employes e where e.NUMEMPLOYE=80) (select ref(i) from Intervenants i where i.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=80));

/*EMPLOYE_INTERVENTIONS*/
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 53) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=53));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 54) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=54));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 55) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=55));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 56) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=56));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 57) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=57));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 58) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=58));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 59) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=59));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 60) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=60));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 61) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=61));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 62) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=62));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 63) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=63));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 64) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=64));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 65) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=65));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 66) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=66));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 67) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=67));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 68) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=68));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 69) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=69));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 71) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=71));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 72) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=72));
INSERT INTO TABLE(SELECT e.EMPLOYE_INTERVENTIONS FROM Employes e WHERE e.NUMEMPLOYE = 80) (select itr.NUMINTERVENTION from Intervenants itr where itr.NUMEMPLOYE=(select ref(e) from Employes e where e.NUMEMPLOYE=80));


/*INTERVENTION_EMPLOYES*/
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=1) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=1));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=2) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=2));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=3) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=3));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=4) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=4));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=5) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=5));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=6) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=6));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=7) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=7));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=8) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=8));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=9) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=9));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=10) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=10));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=11) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=11));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=12) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=12));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=13) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=13));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=14) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=14));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=15) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=15));
insert into table(select i.INTERVENTION_EMPLOYES from Interventions i where i.NUMINTERVENTION=16) (select itr.NUMEMPLOYE from Intervenants itr where itr.NUMINTERVENTION=(select ref(i) from Interventions i where i.NUMINTERVENTION=16));
 /*INTERVENTION_INTERVENANTS*/
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=1));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=2));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=3));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=4));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=5));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=6));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=7));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=8));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=9));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=10));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=11));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=12));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=13));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=14));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=15));
INSERT INTO TABLE (SELECT i.INTERVENTION_INTERVENANTS FROM Interventions i WHERE i.NUMINTERVENTION = 1) (SELECT ref(i) from Intervenants i where i.NUMINTERVENTION = (select ref(itr) from Interventions itr where itr.NUMINTERVENTION=16));


/*VEHICULE_INTERVENTIONS*/
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=3)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 1);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=21)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 2);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=25)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 3);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=10)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 4);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=6)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 5);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=14)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 6);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=1)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 7);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=17)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 8);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=22)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 9);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=2)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 10);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=28)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 11);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=20)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 12);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=8)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 13);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=1)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 14);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=20)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 15);
insert into table (select v.vehicule_interventions from vehicules v where NUMVEHICULE=77)(SELECT REF(i) FROM INTERVENTIONS i WHERE NUMINTERVENTION = 16);

/*MODELE_VEHICULES*/
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 2)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 2));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 3)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 3));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 4)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 4));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 5)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 5));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 6)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 6));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 7)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 7));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 8)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 8));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 9)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 9));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 10)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 10));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 11)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 11));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 12)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 12));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 13)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 13));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 14)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 14));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 15)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 15));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 16)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 16));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 17)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 17));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 18)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 18));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 19)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 19));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 20)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 20));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 21)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 21));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 22)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 22));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 23)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 23));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 24)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 24));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 25)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 25));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 26)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 26));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 27)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 27));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 28)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 28));
INSERT INTO TABLE (SELECT m.MODELE_VEHICULES FROM Modeles m WHERE m.NUMMODELE = 29)(SELECT REF(v) FROM Vehicules v WHERE v.NUMMODELE = (SELECT REF(m) FROM Modeles m WHERE m.NUMMODELE = 29));

/*MARQUE_MODELES*/
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 1)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 1));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 2)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 2));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 3)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 3));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 4)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 4));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 5)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 5));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 6)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 6));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 7)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 7));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 8)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 8));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 9)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 9));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 10)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 10));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 11)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 11));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 12)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 12));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 13)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 13));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 14)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 14));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 15)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 15));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 16)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 16));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 17)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 17));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 18)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 18));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 19)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 19));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 20)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 20));
INSERT INTO TABLE (SELECT ma.MARQUE_MODELES FROM Marques ma WHERE ma.NUMMARQUE = 21)(SELECT  REF(m) FROM Modeles m WHERE m.NUMMARQUE = (SELECT REF(ma) FROM Marques ma WHERE ma.NUMMARQUE = 21));




/*E- Langage d’interrogation de données*/
/*9. Lister les modèles et leur marque.*/
SELECT m.MODELE, DEREF(m.NUMMARQUE).MARQUE as Marque FROM Modeles m;
/*10. Lister les véhicules sur lesquels, il y a au moins une intervention.*/
SELECT DISTINCT DEREF(i.NUMVEHICULE).NUMVEHICULE as NUMVEHICULE FROM Interventions i WHERE i.NUMVEHICULE IS NOT NULL;

/*11. Quelle est la durée moyenne d’une intervention?*/
SELECT AVG(DATEFININTERV - DATEDEBINTERV) AS duree_moyenne FROM Interventions;
/*12. Donner le montant global des interventions dont le coût d’intervention est supérieur à 30000 DA?*/
SELECT SUM(COUTINTERV) AS montant_global FROM Interventions WHERE COUTINTERV > 30000;
/*13. Donner la liste des employés ayant fait le plus grand nombre d’interventions.*/
SELECT e.NOMEMP, e.PRENOMEMP, e.nb_interventions() AS nb_interventions FROM Employes e WHERE e.nb_interventions() = (SELECT MAX(e2.nb_interventions()) FROM Employes e2);
