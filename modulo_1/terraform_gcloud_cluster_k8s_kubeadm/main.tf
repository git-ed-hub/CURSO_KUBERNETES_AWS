provider "google" {
  project     = var.project
  credentials = file(var.credentials_file)
  region      = var.region
  zone        = var.zone
}

resource "google_compute_instance" "controlplane" {
  name                      = "controlplane"
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image
      size  = 30
    }
  }
  network_interface {
    network = "default"
    access_config {
      //necessary even empty
    }
  }
  # Metadata para ejecutar scripts en el inicio
  metadata = {
    user-data = var.user-data
  }



  # Etiquetas opcionales
  tags = ["controlplane"]


}

resource "google_compute_instance" "workernode1" {
  name                      = "workernode1"
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image
      size  = 30
    }
  }
  network_interface {
    network = "default"
    access_config {
      //necessary even empty
    }
  }
  # Metadata para ejecutar scripts en el inicio
  metadata = {
    user-data = var.user-data
  }


  # Etiquetas opcionales
  tags = ["workernode1"]


}

resource "google_compute_instance" "workernode2" {
  name                      = "workernode2"
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image
      size  = 30
    }
  }
  network_interface {
    network = "default"
    access_config {
      //necessary even empty
    }
  }
  # Metadata para ejecutar scripts en el inicio
  metadata = {
    user-data = var.user-data
  }


  # Etiquetas opcionales
  tags = ["workernode2"]


}

# Crear una regla de firewall para abrir el puerto 6443
resource "google_compute_firewall" "allow_6443" {
  project = var.project
  name    = "allow-6443"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["controlplane","workernode1","workernode2"]
}