mysql-server:
    pkg:
        - installed

mysqld:
    service:
        - running
        - enable:True
    require:
        - pkg: mysql-server
