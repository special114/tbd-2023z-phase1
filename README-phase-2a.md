IMPORTANT ❗ ❗ ❗ Please remember to destroy all the resources after each work session. You can recreate infrastructure by creating new PR and merging it to master.

![img.png](doc/figures/destroy.png)

0. The goal of this phase is to create infrastructure, perform benchmarking/scalability tests of sample three-tier lakehouse solution and analyze the results using:
* [TPC-DI benchmark](https://www.tpc.org/tpcdi/)
* [dbt - data transformation tool](https://www.getdbt.com/)
* [GCP Composer - managed Apache Airflow](https://cloud.google.com/composer?hl=pl)
* [GCP Dataproc - managed Apache Spark](https://spark.apache.org/)
* [GCP Vertex AI Workbench - managed JupyterLab](https://cloud.google.com/vertex-ai-notebooks?hl=pl)

Worth to read:
* https://docs.getdbt.com/docs/introduction
* https://airflow.apache.org/docs/apache-airflow/stable/index.html
* https://spark.apache.org/docs/latest/api/python/index.html
* https://medium.com/snowflake/loading-the-tpc-di-benchmark-dataset-into-snowflake-96011e2c26cf
* https://www.databricks.com/blog/2023/04/14/how-we-performed-etl-one-billion-records-under-1-delta-live-tables.html

2. Authors:
   
   ***Grupa nr. 6***

   ***repo: https://github.com/special114/tbd-2023z-phase1***

4. Replace your `main.tf` (in the root module) from the phase 1 with [main.tf](https://github.com/bdg-tbd/tbd-workshop-1/blob/v1.0.36/main.tf)
and change each module `source` reference from the repo relative path to a github repo tag `v1.0.36` , e.g.:
```hcl
module "dbt_docker_image" {
  depends_on = [module.composer]
  source             = "github.com/bdg-tbd/tbd-workshop-1.git?ref=v1.0.36/modules/dbt_docker_image"
  registry_hostname  = module.gcr.registry_hostname
  registry_repo_name = coalesce(var.project_name)
  project_name       = var.project_name
  spark_version      = local.spark_version
}
```


4. Provision your infrastructure.

    a) setup Vertex AI Workbench `pyspark` kernel as described in point [8](https://github.com/bdg-tbd/tbd-workshop-1/tree/v1.0.32#project-setup) 

    b) upload [tpc-di-setup.ipynb](https://github.com/bdg-tbd/tbd-workshop-1/blob/v1.0.36/notebooks/tpc-di-setup.ipynb) to 
the running instance of your Vertex AI Workbench

5. In `tpc-di-setup.ipynb` modify cell under section ***Clone tbd-tpc-di repo***:

   a)first, fork https://github.com/mwiewior/tbd-tpc-di.git to your github organization.

   b)create new branch (e.g. 'notebook') in your fork of tbd-tpc-di and modify profiles.yaml by commenting following lines:
   ```  
        #"spark.driver.port": "30000"
        #"spark.blockManager.port": "30001"
        #"spark.driver.host": "10.11.0.5"  #FIXME: Result of the command (kubectl get nodes -o json |  jq -r '.items[0].status.addresses[0].address')
        #"spark.driver.bindAddress": "0.0.0.0"
   ```
   This lines are required to run dbt on airflow but have to be commented while running dbt in notebook.

   c)update git clone command to point to ***your fork***.
   
   ***https://github.com/special114/tbd-tpc-di***


7. Access Vertex AI Workbench and run cell by cell notebook `tpc-di-setup.ipynb`.

    a) in the first cell of the notebook replace: `%env DATA_BUCKET=tbd-2023z-9910-data` with your data bucket.


   b) in the cell:
         ```%%bash
         mkdir -p git && cd git
         git clone https://github.com/mwiewior/tbd-tpc-di.git
         cd tbd-tpc-di
         git pull
         ```
      replace repo with your fork. Next checkout to 'notebook' branch.
   
    c) after running first cells your fork of `tbd-tpc-di` repository will be cloned into Vertex AI  enviroment (see git folder).

    d) take a look on `git/tbd-tpc-di/profiles.yaml`. This file includes Spark parameters that can be changed if you need to increase the number of executors and
  ```
   server_side_parameters:
       "spark.driver.memory": "2g"
       "spark.executor.memory": "4g"
       "spark.executor.instances": "2"
       "spark.hadoop.hive.metastore.warehouse.dir": "hdfs:///user/hive/warehouse/"
  ```


7. Explore files created by generator and describe them, including format, content, total size.

   Wygenerowane zostały pliki podzielone na trzy Batche. Pliki są różnych rodzajów, ale wszystkie zawierają dane do umieszczenia w tabelach bazy danych. Typy plików to:
   * pliki w formacie .txt zawierają dane tabelaryczne rozdzielone znakiem `|`.
   * pliki FINWIRE... są plikami o stałej szerokości wiersza
   * plik XML CustomerMgmt.xml

   Dodatkowo do każdego pliku z danymi został wygenerowany plik z logami, zawierający informacje o wygenerowanych danych. Wygenerowane pliki mają rozmiar ok 960MB i w większości
   miejsce to zajmują pliki z Batcha nr 1.

   ![Zrzut ekranu z 2024-01-07 13-49-48](https://github.com/special114/tbd-2023z-phase1/assets/51239039/64caba17-d1d9-4676-8089-f23bfd6f8cdc)

9. Analyze tpcdi.py. What happened in the loading stage?

   W loading stage tworzone są cztery bazy danych "digen", "bronze", "silver", "gold". Następnie w bazie "digen" tworzone są tabele oraz wczytywane są dane z wygenerowanych w poprzednim poleceniu plikow. Przetwarzane są tylko pliki z Batcha nr 1. Przed utworzeniem tabeli dane z każdego pliku są umieszczane w buckecie `tbd-2023z-300271-2-data`.

   Na początku przetwarzane są pliki .txt. Do każdego pliku zapisany jest jego schemat i na tej podstawie tworzona jest tabela.
   
   Następnie czytany jest plik xml z tabelą "customer_mgmt".
   
   Na końcu przetwarzane są pliki "FINWIRE...". Te pliki mają stałą szerokość linii, więc każda linia jest wczytywana w całości. Następnie dane zapisywane są w tabeli tymczasowej zawierającej kolumny "rec_type" z typem rekordu, "pts" ze znacznikiem czasowym oraz "line" z całą zawartością wiersza. Później wszystkie wiersze z tabeli tymczasowej na podstawie typu rekordu są parsowane na trzy różne sposoby i zapisywane w tabelach "CMP", "SEC" oraz "FIN".

11. Using SparkSQL answer: how many table were created in each layer?

   ```
db_table_counts = {}
for db in spark.sql("show databases").collect():
    db_name = db.namespace
    spark.sql(f"use {db_name}")
    db_table_counts[db_name] = spark.sql("show tables").count()

for db_name, table_count in db_table_counts.items():
    print(f"Layer: {db_name} - Tables: {table_count}")
   ```
   ![Zrzut ekranu z 2024-01-07 14-55-05](https://github.com/special114/tbd-2023z-phase1/assets/51239039/82fee24c-66ff-422d-83e8-e15490ec1762)


11. Add some 3 more [dbt tests](https://docs.getdbt.com/docs/build/tests) and explain what you are testing. ***Add new tests to your repository.***

   ```
-- Sprawdzenie, że nie istnieją konta bez przypisanego `account_id`

select 
    *
from {{ ref('accounts') }} 
where account_id is NULL


-- Sprawdzenie, że nie istnieje dwóch pracowników tym samym `employee_id`

select 
    employee_id,
    count(employee_id) cnt
from {{ ref('employees') }} 
group by employee_id
having cnt > 1


-- Sprawdzenie, że nie istnieją transakcje z czasem utworzenia `create_timestamp` z przyszłości

select 
    *
from {{ ref('trades') }} 
where create_timestamp > now()
   ```

11. In main.tf update
   ```
   dbt_git_repo            = "https://github.com/mwiewior/tbd-tpc-di.git"
   dbt_git_repo_branch     = "main"
   ```
   so dbt_git_repo points to your fork of tbd-tpc-di. 

12. Redeploy infrastructure and check if the DAG finished with no errors:

***The screenshot of Apache Aiflow UI***
