IMPORTANT ❗ ❗ ❗ Please remember to destroy all the resources after each work session. You can recreate infrastructure by creating new PR and merging it to master.
  
![img.png](doc/figures/destroy.png)


1. Authors:

   ***Grupr no. 6***

   ***repo: https://github.com/special114/tbd-2023z-phase1***
   
2. Fork https://github.com/bdg-tbd/tbd-2023z-phase1 and follow all steps in README.md.

3. Select your project and set budget alerts on 5%, 25%, 50%, 80% of 50$ (in cloud console -> billing -> budget & alerts -> create buget; unclick discounts and promotions&others while creating budget).

  ![img.png](doc/figures/discounts.png)

4. From avaialble Github Actions select and run destroy on main branch.

5. Create new git branch and add two resources in ```/modules/data-pipeline/main.tf```:
    1. resource "google_storage_bucket" "tbd-data-bucket" -> the bucket to store data. Set the following properties:
        * project  // look for variable in variables.tf
        * name  // look for variable in variables.tf
        * location // look for variable in variables.tf
        * uniform_bucket_level_access = false #tfsec:ignore:google-storage-enable-ubla
        * force_destroy               = true
        * public_access_prevention    = "enforced"
        * if checkcov returns error, add other properties if needed
       
    2. resource "google_storage_bucket_iam_member" "tbd-data-bucket-iam-editor" -> assign role storage.objectUser to data service account. Set the following properties:
        * bucket // refere to bucket name from tbd-data-bucket
        * role   // follow the instruction above
        * member = "serviceAccount:${var.data_service_account}"

    ***Link to modified file: https://github.com/special114/tbd-2023z-phase1/blob/master/modules/data-pipeline/main.tf***
   
    ***Code snippet:***
   ```
   resource "google_storage_bucket" "tbd-data-bucket" {
     project                     = var.project_name
     name                        = var.data_bucket_name
     location                    = var.region
     uniform_bucket_level_access = false #tfsec:ignore:google-storage-enable-ubla
     force_destroy               = true
     public_access_prevention    = "enforced"

     #checkov:skip=CKV_GCP_78: "Ensure Cloud storage has versioning enabled"
   }
   
   resource "google_storage_bucket_iam_member" "tbd-data-bucket-iam-editor" {
     bucket = google_storage_bucket.tbd-data-bucket.name
     role   = "roles/storage.objectUser"
     member = "serviceAccount:${var.data_service_account}"
   }
   ```

    Create PR from this branch to **YOUR** master and merge it to make new release. 
    
    ![img.png](doc/figures/task_5_release.png)
    

7. Analyze terraform code. Play with terraform plan, terraform graph to investigate different modules.

    ***describe one selected module and put the output of terraform graph for this module here***
   ***Opisywany moduł: data-pipeline***

   Ten kod Terraform definiuje zasoby na GCP w celu utworzenia Cloud Storage Buckets oraz nadania odpowiednich uprawnień za pomocą ról IAM. Poniżej przedstawiamy opisy poszczególnych zasobów:
   ```
   locals {
    dag_bucket_name_levels = split("/", var.dag_bucket_name)
    dag_bucket_name_length = length(local.dag_bucket_name_levels)
    dag_folder             = element(local.dag_bucket_name_levels, local.dag_bucket_name_length - 1)
    dag_bucket_name        = element(local.dag_bucket_name_levels, 2)
   }
   ```
   Definicja lokalnych zmiennych, które będą używane przy tworzeniu bucketu przechowującego kod związany ze zadaniami z zależnościami skierowanymi (DAG) (plik modules/data-pipeline/resources/data-dag.py).

   ```
   resource "google_storage_bucket" "tbd-code-bucket" {
      project                     = var.project_name
      name                        = var.bucket_name
      location                    = var.region
      uniform_bucket_level_access = false #tfsec:ignore:google-storage-enable-ubla
      force_destroy               = true
      versioning {
        enabled = true
      }
    
      #checkov:skip=CKV_GCP_62: "Bucket should log access"
      #checkov:skip=CKV_GCP_29: "Ensure that Cloud Storage buckets have uniform bucket-level access enabled"
      #checkov:skip=CKV_GCP_78: "Ensure Cloud storage has versioning enabled"
      public_access_prevention = "enforced"
   }
   ```
   Utworzenie bucketa przechowującego dodatkowy kod skryptów wykonywanych jobów (modules/data-pipeline/resources/spark-job.py). Nazwa projektu, nazwa bucketa i jego lokalizacja ustalane są na
   poziomie globalnym. Pozostałe właściwości blokują publiczny dostęp do bucketa, umożliwają wersjonowanie oraz pozwalają niszczenie kubełka nawet jeżeli nie jest pusty (nie przechowujemy
   tu wrażliwych danych). `uniform_bucket_level_access = false` oznacza, że możemy oddzielnie zarządzać uprawnieniami dostępu dla poszczególnych obiektów.

   ```
   resource "google_storage_bucket_iam_member" "tbd-code-bucket-iam-viewer" {
      bucket = google_storage_bucket.tbd-code-bucket.name
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:${var.data_service_account}"
   }
   ```
   Nadanie możliwości przeglądania bucketa dla utworzonego konta serwisowego.

   ```
   resource "google_storage_bucket_object" "job-code" {
      for_each = toset(["spark-job.py"])
      bucket   = google_storage_bucket.tbd-code-bucket.name
      name     = each.value
      source   = "${path.module}/resources/${each.value}"
   }
   ```
   Utworzenie obiektu z plikiem `modules/data-pipeline/resources/spark-job.py` we wcześniej zdefiniowanym buckecie.

   ```
   resource "google_storage_bucket_object" "dag-code" {
      for_each = toset(["data-dag.py"])
      bucket   = local.dag_bucket_name
      name     = "${local.dag_folder}/${each.value}"
      source   = "${path.module}/resources/${each.value}"
   }
   ```
   Utworzenie obiektu z plikiem `modules/data-pipeline/resources/data-dag.py` w buckecie stworzonym przez moduł Composer.

   ```
    resource "google_storage_bucket" "tbd-data-bucket" {
      project                     = var.project_name
      name                        = var.data_bucket_name
      location                    = var.region
      uniform_bucket_level_access = false #tfsec:ignore:google-storage-enable-ubla
      force_destroy               = true
      public_access_prevention    = "enforced"
  
      #checkov:skip=CKV_GCP_78: "Ensure Cloud storage has versioning enabled"
    }
   ```
   Utworzenie bucketu na przechowywanie i przetwarzanie danych przez Apache Airflow.

   ```
   resource "google_storage_bucket_iam_member" "tbd-data-bucket-iam-editor" {
        bucket = google_storage_bucket.tbd-data-bucket.name
        role   = "roles/storage.objectUser"
        member = "serviceAccount:${var.data_service_account}"
   }
   ```
   Nadanie możliwości czytania i zapisywania do powyższego bucketa dla utworzonego konta serwisowego.
   
   
   Przy pomocy komendy uruchomionej w katalogu `tbd-2023z-phase1/modules/data-pipeline`
   `terraform graph | dot -Tsvg > graph.svg`
   wygenerowaliśmy graf zależności.

   ![img.svg](doc/figures/task_7_graph.svg)
   
9. Reach YARN UI

   Połączenie z YARN UI uzyskano poprzez wykonanie komendy połączenia z serwerem `tbd-cluster-m`:
   
   `gcloud compute ssh --zone "europe-west1-b" "tbd-cluster-m" --project "tbd-2023z-300271-2" -- -L 8088:localhost:8088`
   
   i połączeniu się z portem ***8088***.
   
   ![yarn_ui_1](https://github.com/special114/tbd-2023z-phase1/assets/51239039/d2a73b1d-8acc-4d04-be4d-601d61032a46)
   ![yarn_ui_2](https://github.com/special114/tbd-2023z-phase1/assets/51239039/5213a165-1e1a-4a5e-b758-6139a553d0e8)


11. Draw an architecture diagram (e.g. in draw.io) that includes:
    1. VPC topology with service assignment to subnets
    2. Description of the components of service accounts
    3. List of buckets for disposal
    4. Description of network communication (ports, why it is necessary to specify the host for the driver) of Apache Spark running from Vertex AI Workbech
  
    ***place your diagram here***

12. Add costs by entering the expected consumption into Infracost

Plik YAML ze zdefiniowanym oczekiwanym zużyciem:
```
resource_usage:
  #
  # The following usage values apply to individual resources and override any value defined in the resource_type_default_usage section.
  # All values are commented-out, you can uncomment resources and customize as needed.
  #
  module.vpc.module.cloud-router.google_compute_router_nat.nats["nat-gateway"]:
    assigned_vms: 1 # Number of VM instances assigned to the NAT gateway
    monthly_data_processed_gb: 2.0 # Monthly data processed (ingress and egress) by the NAT gateway in GB
  module.data-pipelines.google_storage_bucket.tbd-code-bucket:
    storage_gb: 1.0 # Total size of bucket in GB.
    monthly_class_a_operations: 10 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 10 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 1.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 1.0 # Same continent.
      worldwide: 0.0 # Worldwide excluding Asia, Australia.
      asia: 0.0 # Asia excluding China, but including Hong Kong.
      china: 0.0 # China excluding Hong Kong.
      australia: 0.0 # Australia.
  module.data-pipelines.google_storage_bucket.tbd-data-bucket:
    storage_gb: 5.0 # Total size of bucket in GB.
    monthly_class_a_operations: 10 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 10 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 5.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 5.0 # Same continent.
      worldwide: 0.0 # Worldwide excluding Asia, Australia.
      asia: 0.0 # Asia excluding China, but including Hong Kong.
      china: 0.0 # China excluding Hong Kong.
      australia: 0.0 # Australia.
  module.gcr.google_container_registry.registry:
    storage_gb: 2.0 # Total size of bucket in GB.
    monthly_class_a_operations: 5 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 5 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 2.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 2.0 # Same continent.
      worldwide: 0.0 # Worldwide excluding Asia, Australia.
      asia: 0.0 # Asia excluding China, but including Hong Kong.
      china: 0.0 # China excluding Hong Kong.
      australia: 0.0 # Australia.
  module.vertex_ai_workbench.google_storage_bucket.notebook-conf-bucket:
    storage_gb: 3.0 # Total size of bucket in GB.
    monthly_class_a_operations: 0 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 0 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 3.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 3.0 # Same continent.
      worldwide: 0.0 # Worldwide excluding Asia, Australia.
      asia: 0.0 # Asia excluding China, but including Hong Kong.
      china: 0.0 # China excluding Hong Kong.
      australia: 0.0 # Australia.

```

Wyjście programu infracost:
```
➜  tbd-2023z-phase1 git:(master) ✗ infracost breakdown --path . --usage-file infracost-usage.yml
Evaluating Terraform directory at .
  ✔ Downloading Terraform modules 
  ✔ Evaluating Terraform directory 
Warning: Input values were not provided for following Terraform variables: "variable.project_name", "variable.ai_notebook_instance_owner". Use --terraform-var-file or --terraform-var to specify them.
  ✔ Retrieving cloud prices to calculate costs 

Project: special114/tbd-2023z-phase1

 Name                                                                                Monthly Qty  Unit             Monthly Cost 
                                                                                                                                
 module.data-pipelines.google_storage_bucket.tbd-code-bucket                                                                    
 ├─ Storage (standard)                                                                         1  GiB                     $0.02 
 ├─ Object adds, bucket/object list (class A)                                              0.001  10k operations          $0.00 
 ├─ Object gets, retrieve bucket/object metadata (class B)                                 0.001  10k operations          $0.00 
 └─ Network egress                                                                                                              
    ├─ Data transfer in same continent                                                         5  GB                      $0.10 
    ├─ Data transfer to worldwide excluding Asia, Australia (first 1TB)            Monthly cost depends on usage: $0.12 per GB  
    ├─ Data transfer to Asia excluding China, but including Hong Kong (first 1TB)  Monthly cost depends on usage: $0.12 per GB  
    ├─ Data transfer to China excluding Hong Kong (first 1TB)                      Monthly cost depends on usage: $0.23 per GB  
    └─ Data transfer to Australia (first 1TB)                                      Monthly cost depends on usage: $0.19 per GB  
                                                                                                                                
 module.data-pipelines.google_storage_bucket.tbd-data-bucket                                                                    
 ├─ Storage (standard)                                                                         5  GiB                     $0.10 
 ├─ Object adds, bucket/object list (class A)                                              0.001  10k operations          $0.00 
 ├─ Object gets, retrieve bucket/object metadata (class B)                                 0.001  10k operations          $0.00 
 └─ Network egress                                                                                                              
    ├─ Data transfer in same continent                                                         5  GB                      $0.10 
    ├─ Data transfer to worldwide excluding Asia, Australia (first 1TB)            Monthly cost depends on usage: $0.12 per GB  
    ├─ Data transfer to Asia excluding China, but including Hong Kong (first 1TB)  Monthly cost depends on usage: $0.12 per GB  
    ├─ Data transfer to China excluding Hong Kong (first 1TB)                      Monthly cost depends on usage: $0.23 per GB  
    └─ Data transfer to Australia (first 1TB)                                      Monthly cost depends on usage: $0.19 per GB  
                                                                                                                                
 module.gcr.google_container_registry.registry                                                                                  
 ├─ Storage (standard)                                                                         2  GiB                     $0.05 
 ├─ Object adds, bucket/object list (class A)                                             0.0005  10k operations          $0.00 
 ├─ Object gets, retrieve bucket/object metadata (class B)                                0.0005  10k operations          $0.00 
 └─ Network egress                                                                                                              
    ├─ Data transfer in same continent                                                         5  GB                      $0.10 
    ├─ Data transfer to worldwide excluding Asia, Australia (first 1TB)            Monthly cost depends on usage: $0.12 per GB  
    ├─ Data transfer to Asia excluding China, but including Hong Kong (first 1TB)  Monthly cost depends on usage: $0.12 per GB  
    ├─ Data transfer to China excluding Hong Kong (first 1TB)                      Monthly cost depends on usage: $0.23 per GB  
    └─ Data transfer to Australia (first 1TB)                                      Monthly cost depends on usage: $0.19 per GB  
                                                                                                                                
 module.vertex_ai_workbench.google_storage_bucket.notebook-conf-bucket                                                          
 ├─ Storage (standard)                                                                         3  GiB                     $0.06 
 └─ Network egress                                                                                                              
    ├─ Data transfer in same continent                                                         5  GB                      $0.10 
    ├─ Data transfer to worldwide excluding Asia, Australia (first 1TB)            Monthly cost depends on usage: $0.12 per GB  
    ├─ Data transfer to Asia excluding China, but including Hong Kong (first 1TB)  Monthly cost depends on usage: $0.12 per GB  
    ├─ Data transfer to China excluding Hong Kong (first 1TB)                      Monthly cost depends on usage: $0.23 per GB  
    └─ Data transfer to Australia (first 1TB)                                      Monthly cost depends on usage: $0.19 per GB  
                                                                                                                                
 module.vpc.module.cloud-router.google_compute_router_nat.nats["nat-gateway"]                                                   
 ├─ Assigned VMs (first 32)                                                                  730  VM-hours                $1.02 
 └─ Data processed                                                                             2  GB                      $0.09 
                                                                                                                                
 OVERALL TOTAL                                                                                                            $1.74 
──────────────────────────────────
31 cloud resources were detected:
∙ 5 were estimated, all of which include usage-based costs, see https://infracost.io/usage-file
∙ 23 were free, rerun with --show-skipped to see details
∙ 3 are not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┓
┃ Project                                            ┃ Monthly cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━┫
┃ special114/tbd-2023z-phase1                        ┃ $2           ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━┛

```

11. Some resources are not supported by infracost yet. Estimate manually total costs of infrastructure based on pricing costs for region used in the project. Include costs of cloud composer, dataproc and AI vertex workbanch and them to infracost estimation.

Zasoby niewspierane przez Infracost:
```
∙ 3 are not supported yet, see https://infracost.io/requested-resources:
  ∙ 1 x google_composer_environment
  ∙ 1 x google_dataproc_cluster
  ∙ 1 x google_notebooks_instance
```

    Estimation and references:
|name                                                                                                                                                                                                   |quantity                                                                             |region      |service_id    |sku                                                                              |product_description                   |unit_price, USD                                                                                        |total_price, USD  |notes                    |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|------------|--------------|---------------------------------------------------------------------------------|--------------------------------------|-------------------------------------------------------------------------------------------------------|------------------|-------------------------|
|Cloud Composer                                                                                                                                                                                         |1                                                                                    |europe-west1|1992-3666-B975|Look up for SKU https://cloud.google.com/skus/?currency=USD&filter=1992-3666-B975|CP-COMPOSER                           |11.830892857142855                                                                                     |11.830892857142855|                         |
|Licensing Fee for Google Cloud Dataproc (CPU cost)                                                                                                                                                     |600                                                                                  |global      |6F81-5844-456A|DC33-D3C7-25CA                                                                   |CP-DATAPROC                           |0.01                                                                                                   |6                 |                         |
|E2 Instance Core running in EMEA                                                                                                                                                                       |200                                                                                  |europe-west1|6F81-5844-456A|9FE0-8F60-A9F0                                                                   |CP-COMPUTEENGINE-VMIMAGE-E2-STANDARD-2|0.02399337                                                                                             |4.798674          |1 x Dataproc master node |
|E2 Instance Ram running in EMEA                                                                                                                                                                        |800                                                                                  |europe-west1|6F81-5844-456A|F268-6CE7-AC16                                                                   |CP-COMPUTEENGINE-VMIMAGE-E2-STANDARD-2|0.00321609                                                                                             |2.572872          |1 x Dataproc master node |
|E2 Instance Core running in EMEA                                                                                                                                                                       |200                                                                                  |europe-west1|6F81-5844-456A|9FE0-8F60-A9F0                                                                   |CP-COMPUTEENGINE-VMIMAGE-E2-STANDARD-2|0.02399337                                                                                             |4.798674          |1 x notebook             |
|E2 Instance Ram running in EMEA                                                                                                                                                                        |800                                                                                  |europe-west1|6F81-5844-456A|F268-6CE7-AC16                                                                   |CP-COMPUTEENGINE-VMIMAGE-E2-STANDARD-2|0.00321609                                                                                             |2.572872          |1 x notebook             |
|E2 Instance Core running in EMEA                                                                                                                                                                       |200                                                                                  |europe-west1|6F81-5844-456A|9FE0-8F60-A9F0                                                                   |CP-COMPUTEENGINE-VMIMAGE-E2-STANDARD-2|0.02399337                                                                                             |4.798674          |2 x Dataproc worker nodes|
|E2 Instance Ram running in EMEA                                                                                                                                                                        |800                                                                                  |europe-west1|6F81-5844-456A|F268-6CE7-AC16                                                                   |CP-COMPUTEENGINE-VMIMAGE-E2-STANDARD-2|0.00321609                                                                                             |2.572872          |2 x Dataproc worker nodes|
|Cloud Composer                                                                                                                                                                                         |1                                                                                    |europe-west1|1992-3666-B975|Look up for SKU https://cloud.google.com/skus/?currency=USD&filter=1992-3666-B975|CP-COMPOSER                           |14.159071428571428                                                                                     |14.159071428571428|                         |
|AI Pipeline job: Managed Pipeline job count                                                                                                                                                            |5                                                                                    |global      |C7E2-9256-1C43|2B84-9CF1-241F                                                                   |CP-VERTEX-PIPELINES-JOB               |0.03                                                                                                   |0.15              |                         |
|Data Compute Unit (milli) Hours - Dataproc Serverless Batch - europe-west1 (26.07142857142857 hours)                                                                                                   |9                                                                                    |europe-west1|363B-8851-170D|CDF7-AB83-7649                                                                   |CP-DATAPROC-SERVERLESS                |0.066007                                                                                               |15.49             |                         |
|Dataproc Serverless Shuffle Storage GB-Months - europe-west1 (26.07142857142857 hours)                                                                                                                 |0                                                                                    |europe-west1|363B-8851-170D|DCAE-7EB2-5861                                                                   |CP-DATAPROC-SERVERLESS                |0.04                                                                                                   |0                 |                         |
|Storage PD Capacity                                                                                                                                                                                    |30                                                                                   |europe-west1|6F81-5844-456A|D973-5D65-BAB2                                                                   |CP-COMPUTEENGINE-STORAGE-PD-READONLY  |0                                                                                                      |0                 |                         |
|Storage PD Capacity                                                                                                                                                                                    |175.4794520547945                                                                    |europe-west1|6F81-5844-456A|D973-5D65-BAB2                                                                   |CP-COMPUTEENGINE-STORAGE-PD-READONLY  |0.04                                                                                                   |7.019178082191781 |                         |
|                                                                                                                                                                                                       |                                                                                     |            |              |                                                                                 |                                      |                                                                                                       |                  |                         |
|                                                                                                                                                                                                       |                                                                                     |            |              |                                                                                 |                                      |Total Price:                                                                                           |76.76378036790607 |                         |
|                                                                                                                                                                                                       |                                                                                     |            |              |                                                                                 |                                      |* Sustained use discount (SUD) is not included. You may need to apply discounts separately for each SKU|                  |                         |
|                                                                                                                                                                                                       |                                                                                     |            |              |                                                                                 |                                      |                                                                                                       |                  |                         |
|Prices are in US dollars, effective date is 2023-11-24T18:27:36.697Z.                                                                                                                                  |                                                                                     |            |              |                                                                                 |                                      |                                                                                                       |                  |                         |
|                                                                                                                                                                                                       |                                                                                     |            |              |                                                                                 |                                      |                                                                                                       |                  |                         |
|The estimated fees provided by Google Cloud Pricing Calculator are for discussion purposes only and are not binding on either you or Google. Your actual fees may be higher or lower than the estimate.|                                                                                     |            |              |                                                                                 |                                      |                                                                                                       |                  |                         |
|                                                                                                                                                                                                       |                                                                                     |            |              |                                                                                 |                                      |                                                                                                       |                  |                         |
|Url to the estimate:                                                                                                                                                                                   |https://cloud.google.com/products/calculator/#id=c7df1b9d-b774-40eb-8c17-7a2801b512e5|            |              |                                                                                 |                                      |                                                                                                       |                  |                         |
* Użycie preemptible(spot) instances - są one tańsze niż zwykłe zasoby
* Optymalizacja czasu uruchomienia maszyn wirtualnych - czas wskazany w kalkulatorze jest orientacyjny i faktycznyczas uruchomienia maszyny może być niższy
* Usuwanie zasobów obliczeniowych kiedy są nieużywane
* Optymalne korzystanie z bucketów - powoływanie tańszych instancji dla zasobów, które są rzadko używane
    
12. Create a BigQuery dataset and an external table
    
```
special114@tbd-cluster-m:~$ bq mk dataset
Dataset 'tbd-2023z-300271-2:dataset' successfully created.

special114@tbd-cluster-m:~$ bq mk --table --external_table_definition=@ORC=gs://cloud-samples-data/bigquery/us-states/us-states.orc dataset.tbd_table
Table 'tbd-2023z-300271-2:dataset.tbd_table' successfully created.

special114@tbd-cluster-m:~$ bq show dataset.tbd_table
Table tbd-2023z-300271-2:dataset.tbd_table

   Last modified           Schema            Type     Total URIs   Expiration   Labels  
 ----------------- ---------------------- ---------- ------------ ------------ -------- 
  24 Nov 18:48:23   |- name: string        EXTERNAL   1                                 
                    |- post_abbr: string                                                

```

   
W plikach ORC jest zawarta informacja o kolumnach znajdujących się w tym pliku, przez co nie trzeba osobno podawać schematu bazy, ale jest on tworzony na podstawie pliku.
  
13. Start an interactive session from Vertex AI workbench (steps 7-9 in README):

![Zrzut ekranu z 2023-11-24 20-05-51](https://github.com/special114/tbd-2023z-phase1/assets/51239039/681561b2-12f6-42e9-8853-3f1d5151aaeb)

   
14. Find and correct the error in spark-job.py

![Zrzut ekranu z 2023-11-24 20-34-50](https://github.com/special114/tbd-2023z-phase1/assets/51239039/bc13279f-9a3b-4897-aa7f-f9057b9dcf8c)

Błąd wynika z braku możliwości zapisu do wskazanego bucketa. Należy zmienić zmienną DATA_BUCKET aby wskazywała na bucket utworzony przez nas.
Po zmianie adresu bucketa na poprawny, błąd już nie występuje.

[Link do zmiany w kodzie](https://github.com/bdg-tbd/tbd-2023z-phase1/commit/07baf3410593ea653efb8f2c95d193eb1643261f)

![Zrzut ekranu z 2023-11-30 20-57-34](https://github.com/special114/tbd-2023z-phase1/assets/51239039/8833bb75-e5b3-4da8-b561-f7423c4c5c3e)


15. Additional tasks using Terraform:

    1. Add support for arbitrary machine types and worker nodes for a Dataproc cluster and JupyterLab instance

    [Link do zmiany w kodzie](https://github.com/bdg-tbd/tbd-2023z-phase1/commit/9052cf4a56b10355dac468e11985627568659ea0)
    
    2. Add support for preemptible/spot instances in a Dataproc cluster

    [Link do zmiany w kodzie](https://github.com/bdg-tbd/tbd-2023z-phase1/commit/01b925e3667eca2ff22c1e0de5a33bf08e35d867)
    
    3. Perform additional hardening of Jupyterlab environment, i.e. disable sudo access and enable secure boot
    
    [Link do zmiany w kodzie](https://github.com/bdg-tbd/tbd-2023z-phase1/commit/3585b0787ef4285ba1751535a2ee2dcb6bf9dfa3)

    4. (Optional) Get access to Apache Spark WebUI

    Połączyliśmy się z klastrem Dataproc. Uruchomiliśmy komendę `spark-shell` i w przeglądarce poprzez Hadoop UI dostaliśmy się do Apache Spark WebUI.
    
    ![Zrzut ekranu z 2023-11-30 22-39-52](https://github.com/special114/tbd-2023z-phase1/assets/51239039/c2d40854-04a6-4c0d-95c3-1acf33c7e99a)

    ![Zrzut ekranu z 2023-11-30 22-32-24](https://github.com/special114/tbd-2023z-phase1/assets/51239039/35fe5162-7d9f-4615-83d5-f1ec41a5e612)

