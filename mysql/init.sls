mysql-server:
    pkg.installed

mysqld:
    service:
        - running
    require:
        - pkg.installed: mysql-server
