0. The goal of phase 2b is to perform benchmarking/scalability tests of sample three-tier lakehouse solution.

1. In main.tf, change machine_type at:

```
module "dataproc" {
  depends_on   = [module.vpc]
  source       = "github.com/bdg-tbd/tbd-workshop-1.git?ref=v1.0.36/modules/dataproc"
  project_name = var.project_name
  region       = var.region
  subnet       = module.vpc.subnets[local.notebook_subnet_id].id
  machine_type = "e2-standard-2"
}
```

and subsititute "e2-standard-2" with "e2-standard-4".

2. If needed request to increase cpu quotas (e.g. to 30 CPUs): 
https://console.cloud.google.com/apis/api/compute.googleapis.com/quotas?project=tbd-2023z-9918

3. Using tbd-tpc-di notebook perform dbt run with different number of executors, i.e., 1, 2, and 5, by changing:
```
 "spark.executor.instances": "2"
```

in profiles.yml.

4. In the notebook, collect console output from dbt run, then parse it and retrieve total execution time and execution times of processing each model. Save the results from each number of executors. 

![Zrzut ekranu z 2024-01-16 19-34-52](https://github.com/special114/tbd-2023z-phase1/assets/51239039/74ad64c4-9c79-41da-bc13-07d4543e2988)


5. Analyze the performance and scalability of execution times of each model. Visualize and discucss the final results.

Poszczególne czasy wykonania dla modeli umieściliśmy na wykresach poniżej. Na poszczególnych wykresach znajdują się modele z podobnymi czasami wykonania.

![output1](https://github.com/special114/tbd-2023z-phase1/assets/51239039/fdf99985-54e2-46ab-98fa-8af7079add6d)
![output2](https://github.com/special114/tbd-2023z-phase1/assets/51239039/b08fbff0-67f0-4d1f-ac99-b52f444fc82a)
![output3](https://github.com/special114/tbd-2023z-phase1/assets/51239039/48bdf90c-6a74-45ea-8784-3dc75d5fed66)
![output4](https://github.com/special114/tbd-2023z-phase1/assets/51239039/df950e6a-99b4-470d-bd5a-cc953afe1467)
![output5](https://github.com/special114/tbd-2023z-phase1/assets/51239039/6c5174a1-48cc-437b-bcfc-4fb8e4dd305b)

Z wykresów widać, że dla modeli bardziej złożonych obliczeniowo istnieje szczególnie duży zysk pomiędzy użyciem jednego, a dwóch węzłów wykonawczych. Mniej skomplikowane modele mają podobne czasy wykonania na każdej liczbie węzłów. Może to wynikać z tego, że danych jest za mało, żeby Spark rozdzielał je na większą liczbę węzłów lub po prostu sama obróbka i synchronizacja danych trwa dłużej niż obliczenia.

Na poniższym wykresie przedstawiliśmy całkowity czas przetwarzania modeli dla poszczególnej liczby procesorów.

![overall](https://github.com/special114/tbd-2023z-phase1/assets/51239039/d467f2e4-787e-4f77-8d7d-a7aec042d782)

Wykres potwierdza, że szczeólnie duży różnica jest pomiędzy użyciem jednego, a dwóch węzłow wykonawczych. Czasy wykonania dla rosnącej liczby węzłów mają tendencję do bycia lepszymi, jednak dla 5-ciu węzłów czas jest gorszy niż dla czterech. To również może wynikać z faktu, że danych jest niewystarczająco dużo żeby osiągać zyski z dodatkowego skalowania.

Ogólny wniosek nasuwa się taki, aby ilość węzłów wykonawczych dobierać do konkretnego zadania i nie zawsze więcej oznacza lepiej.



   
