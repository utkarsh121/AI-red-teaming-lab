# AI Red Teaming Lab

**AI Red Teaming Lab** is a hands-on educational project designed to teach foundational and advanced concepts in AI security through executable lab notebooks and automated setup scripts.

This lab walks users through real adversarial attack techniques — including evasion, poisoning, inference, and extraction — on machine learning models and demonstrates how to use tools like the **Adversarial Robustness Toolbox (ART)** to explore vulnerabilities in AI systems.

---

## ⚙️ Installation

### Requirements

The lab is intended to be used on a Unix-compatible development environment (e.g., Ubuntu). The provided installer scripts will:

* Install Python, pip, and JupyterLab
* Create a Python virtual environment
* Download required libraries (scikit-learn, numpy, pandas, matplotlib, ART, etc.)
* Set up datasets and execute Jupyter notebooks

### Run Installation

```bash
bash lab_installer.sh
```

This script will check for `curl`, download the full installation script (`lab_installer_main.sh`), and begin environment setup.

---

## 📁 Project Structure

```
AI-red-teaming-lab/
├── lab_installer.sh
├── lab_installer_main.sh
├── notebooks/
│   ├── START_HERE.ipynb
│   ├── Lab1_Evasion_Attack.ipynb
│   ├── Lab2_Poisoning_Attack.ipynb
│   ├── Lab3_Inference_Attack.ipynb
│   ├── Lab4_Extraction_Attack.ipynb
│   └── ...
├── datasets/
│   ├── sms_spam_collection_dataset.csv
│   └── nursery_dataset.csv
├── outputs/
│   └── charts_and_results/
└── README.md
```

---

## 📘 Notebooks Overview

### 🪪 START_HERE.ipynb

**Description:** Introductory notebook to guide users through setup verification and how to work with the lab environment.

**Learning Goals:**

* Confirm environment is working
* Launch JupyterLab
* Understand navigation between notebooks

---

### 🧠 Lab 1: **Evasion Attack**

**File:** `Lab1_Evasion_Attack.ipynb`

**Summary:** Train a text-based classifier (e.g., SMS spam detector) and perform an **evasion attack** that perturbs inputs to cause the model to misclassify.

**Concepts Covered:**

* TF-IDF text vectorization
* Logistic regression classifier
* Introduction to adversarial attacks
* Using ART’s `HopSkipJump` attack

**Result:** Understand how small perturbations to inputs can fool deployed models.

---

### 💀 Lab 2: **Poisoning Attack**

**File:** `Lab2_Poisoning_Attack.ipynb`

**Summary:** Demonstrates how to **poison training data** such that model behavior is corrupted when later used in production.

**Concepts Covered:**

* Training/validation dataset manipulation
* Backdoor patterns
* Targeted vs. untargeted poisoning
* Evaluating model resilience

**Result:** See how model performance shifts when poisoned data is introduced.

---

### 🔍 Lab 3: **Inference Attack**

**File:** `Lab3_Inference_Attack.ipynb`

**Summary:** Shows how adversaries can perform **inference attacks** to extract sensitive properties about training data.

**Concepts Covered:**

* Membership inference techniques
* Shadow models (optional)
* Risk evaluation

**Result:** Determine the level of privacy leakage from a deployed model.

---

### 🧬 Lab 4: **Extraction Attack**

**File:** `Lab4_Extraction_Attack.ipynb`

**Summary:** Practical exploration of **model extraction attacks**, where an attacker tries to replicate a target model via API queries.

**Concepts Covered:**

* Black-box querying
* Surrogate model training
* Evaluation of extraction fidelity

**Result:** Understand how models can be reverse-engineered.

---

## 📊 Datasets

The `datasets/` folder contains the CSV datasets used in the labs:

* **sms_spam_collection_dataset.csv** — SMS text and labels for spam classification
* **nursery_dataset.csv** — Example structured dataset for learning exercises

> ⚠️ Make sure these are in place before running the respective notebooks.

---

## 📦 Dependencies

The major Python dependencies installed include:

* `numpy`
* `pandas`
* `scikit-learn`
* `matplotlib`
* `adversarial-robustness-toolbox (ART)`

---

## 🎯 Goals

After completing these labs, you will be able to:

* Understand common adversarial attack categories against AI models
* Set up a reproducible Python security testing environment
* Experiment with open-source AI adversarial tools
* Interpret attack success and model resilience metrics
* Build a foundational skillset for AI red teaming and security evaluation

---

## 📖 References

* Adversarial Machine Learning and AI Security
* Adversarial Robustness Toolbox (ART)
* MITRE ATLAS adversarial threat framework
* Prompt injection, jailbreaks, and generative model attacks

---


## ✨ Contributing

If you want to expand this lab:

* Add more attack categories (e.g., generative model prompt injection)
* Include defense notebooks (e.g., robust training)
* Provide evaluation challenges and grading scripts

Thank you for contributing!
