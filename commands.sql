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
create type Temploye;
create type Tvehicule;
create type Tclient;
create type Tmodele;
create type Tmarque;

create or replace type Tintervenants as object (
NUMINTERVENTION ref Tinterventions,
NUMEMPLOYE ref Temploye,
DATEDEBUT DATE,
DATEFIN DATE
);
/

create type tset_intervenants as table of Tintervenants;

create or replace type Temploye as object(
NUMEMPLOYE number,
NOMEMP varchar2(20),
PRENOMEMP varchar2(20),
CATEGORIE varchar2(20),
SALAIRE float,
EMPLOYE_INTERVENANTS ref Tintervenants
);
/

create type tset_employes as table of Temloye;

create or replace type Tinterventions as object(
NUMINTERVENTION number,
NUMVEHICULE ref Tvehicule,
TYPEINTERVENTION varchar2(20),
DATEDEBINTERV date,
DATEFININTERV date,
COUTINTERV float,
INTERVENTION_INTERVENANTS ref Tintervenants,
INTERVENTION_EMPLOYES tset_employes
);
/

create type tset_interventions as table of Tinterventions;

alter type Temploye add attribute EMPLOYE_INTERVENTIONS tset_interventions cascade;

create or replace type Tvehicule as object(
NUMVEHICULE numver,
NUMCLIENT ref Tclient,
NUMMODELE ref Tmodele,
NUMIMMAT VARCHAR2(20),
ANNEE NUMBER,
VEHICULE_INTERVENTIONS tset_interventions
);
/

create type tset_vehicules as table of Tvehicule;

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
MODELE_VEHICULES tset_vehicule
);
/

create type tset_modeles as table of Tmodele;

create or replace type Tmarque as object (
NUMMARQUE number,
MARQUE varchar2(20),
PAYS  varcar2(20),
MARQUE_MODELES tset_modeles
);
/

/*6. Définir les méthodes permettant de :*/

/*calculer pour chaque employe, le nombre d'interventions effectuées*/
alter type Temploye add member function nb_interventions return numeric cascade;
create or replace type body Temploye as
  member function nb_interventions return numeric is
  BEGIN
    select count(cast(multiset(
        select i.INTERVENTION_INTERVENANTS
        from table(self.EMPLOYE_INTERVENTIONS) i, table(i.INTERVENTION_INTERVENANTS) j
        where j.NUMEMPLOYE = self.NUMEMPLOYE
        ) as Tset_intervenants))
        into nb from dual;
    RETURN nb;
  END nb_interventions;
END;
/

/*calculer pour chaque marque le nombre de modèles*/
alter type Tmarque add member  function nb_modeles return numeric cascade;
create or remplace type body Tmarque as
  member function nb_modeles return numeric is
    nb numeric;
  BEGIN
    select count(cast(multiset(
      select m.MODELE from table(self.MARQUE_MODELES) m
    ) as Tset_modeles))
    into nb from dual;
    return nb;
  END nb_modeles;
 END;
 /
 
 /*calculer pour chaque modele, le nombre de véhicules*/
 alter type Tmodele add member function nb_vehicules return numeric cascade;
 create or replace type body Tmodele as
   member function nb_vehicules return numeric is
     nb numeric;
   BEGIN
     select count(cast(multiset(
       select * from table(self.MODELE_VEHICULES)
     ) as Tset_vehicule))
     into nb from dual;
     return nb;
   END nb_vehicules;
 END;
 /
 
 /*lister pour chaque client, ses véhicules*/
 alter type Tclient add member function lister_vehicules return numeric cascade;
 create or replace type body Tclient as
   member produre lister_vehicules is
   BEGIN
     for v in (
       select * from table(self.CLIENT_VEHICULES)
     )
     loop
       DBMS_OUTPUT.PUT_LINE(v);
     end loop;
   END lister_vehicules;
 END;
 /
 
/*calculer pour chaque marque, son chiffre d'affaire*/
alter type Tmarque add member function chiffre_affaire return numeric cascade;
create or replace type body Tmarque as
  member function chiffre_affaire return numeric is
    ca numeric;
  BEGIN
    select sum(i.COUNTINTERV) into ca
    from table(select cast(multiset(
                 select v.VEHICULE_INTERVENTIONS from table(
	                  select m.MARQUE_MODELES from Tmarque m where m.NUMMARQUE = self.NUMMARQUE
	                ) as Tset_intervenrions)
	  ) i;
	    return ca;
	  END chiffre_affaire;
	END;
	/


/* 7. Définir les tables nécessaires à la base de données.*/
-- Création de la table pour le type Tmarque
CREATE TABLE Marques OF Tmarque (
   constraint pk_marques primary key(nom)
) NESTED TABLE MARQUE_MODELES STORE AS Modeles_table;

-- Création de la table pour le type Tmodele  
CREATE TABLE Modeles OF Tmodele (
   constraint pk_modeles primary key(nom)
) NESTED TABLE MODELE_VEHICULES STORE AS Vehicules_table;

-- Création de la table pour le type Tclient
CREATE TABLE Clients OF Tclient (
    constraint pk_clients primary key(nom)
) NESTED TABLE CLIENT_VEHICULES STORE AS Vehicules_table;

-- Création de la table pour le type Tvehicule
CREATE TABLE Vehicules OF Tvehicule (
    constraint pk_vehicules primary key(nom)
) NESTED TABLE VEHICULE_INTERVENTIONS STORE AS Interventions_table;

-- Création de la table pour le type Temploye
CREATE TABLE Employes OF Temploye (
    constraint pk_employes primary key(nom)
) NESTED TABLE EMPLOYE_INTERVENANTS STORE AS Intervenants_table;

-- Création de la table pour le type Tinterventions  
CREATE TABLE Interventions OF Tinterventions (
    constraint pk_interventions primary key(nom)
) NESTED TABLE INTERVENTION_INTERVENANTS STORE AS Intervenants_table
  NESTED TABLE INTERVENTION_EMPLOYES STORE AS Employes_table;
Vous avez envoyé
CREATE TABLE Intervenants OF Tintervenants (
    constraint pk_intervenant primary key(nom)
) NESTED TABLE PRIMARY KEY NESTED;
