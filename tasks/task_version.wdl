version 1.0

task version_capture {
  input {
    String? timezone
  }
  meta {
    volatile: true
  }
  command {
    cbird_version="C-BIRD v0.9.4.0"
    ~{default='' 'export TZ=' + timezone}
    date +"%Y-%m-%d" > TODAY
    echo "$cbird_version" > CBIRD_VERSION
  }
  output {
    String date = read_string("TODAY")
    String cbird_version = read_string("CBIRD_VERSION")
  }
  runtime {
    memory: "128 MB"
    cpu: 1
    docker: "kincekara/bash:alpine"
    disks: "local-disk 10 HDD"
    dx_instance_type: "mem1_ssd1_v2_x2" 
  }
}