1. Pour n'importe lequel URL on va aterrir vers un même servlet
2. Mila fantatra daholo ny URL rehetra ao anatin'le test
    . création un annotation(mandray en paramètre un URL)
    . Test comme un main hoe voaray ve le URL

3. Rehfa url tsy anatin'ilay annotation dia rehefa tsy misy de atao annotation

Crée annotation au niveau classe
    cree classe 3 de jerena zay classe
    scan classe hoe iza avy no annoté controllers
    tadivaina daholo indray zay annoté amin le url
Sprint 3: rehefa mi demarre le application de misy bout de code lancé, mi scann ny class rehetra anaty classpath rehetra 
atao anay init anle servlet
4.  4:fonction qui retourne string (verifie) de raha izay de atao de afficher-na le izy
Framework
    4 bis: creation classe ModelView
    - attribut vue
    Test:
        Raha type Model view dia alefa any aminle page
        
5. Ao anaty ModelView Map(data):
    String le:
    Valeur type object:
6. sprint 3 ters 
 De url misy accolade de tsy tonga dia hoe misy execption
Sprint 6: rehefa mitovy le anaran'ilay anaran'ila variable syavy any amin'ny request.getParameter
De iny no apteraka
6 bis: misy requestParam
6 ters: efa le acollade no ailaina

7. Saharana ny Get sy ny Post rehefa misy an'ilay requete: donc mety hitovy le url

8. Sprint 8: traitement des données envoyés par les vues: Raha oahtra ka map: string, object -> creer map: alaina daholo ny req.getParameterValues -> 
   Sprint 8.bis: 
    Ao anatin'ilay controller tonga dia object no atao ao, ohatra hoe formulaire d Employe, de tonga dia objet de type Emp

9. Mi return json rehefa misy annotation @Json na @Annotation
    - rehefa tsy modelView
    - rehefa zay de le data ao anatiny no alefa
    - format:
    {
        status:
        code:
        data:{
            "id":
            "name":
        }
        // rehefa liste de ohatran zao
        data :[
            comptes: {
                "id": ,
                "name": ,

            }
        ]
    } 