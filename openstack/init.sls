include:
    - epel
    - selinux
    - mysql
    - apache
    - memcached
    - avahi

permissive:
    selinux.mode:
        - require:
            - pkg: libsemanage
            - pkg: setools-console

openstack-pkgs:
    pkg.installed:
        - repo: epel-testing
        - require:
            - pkg.installed: mysql-server
        - names:
            - openstack-nova
            - openstack-keystone
            - openstack-quantum
            - openstack-swift
            - openstack-swift-account
            - openstack-swift-container
            - openstack-swift-object
            - openstack-swift-plugin-swift3
            - openstack-swift-proxy
            - openstack-dashboard
            - openstack-utils
            - qpid-cpp-server
            # if RHEL 6.3
            - dnsmasq-utils
            # elif <= RHEL 6.2:
            # cmd.run: openstack-config --set /etc/nova/nova.conf DEFAULT force_dhcp_release False

mysqld:
    service.running:
    require:
        - pkg.installed: mysql-server

nova-support:
    service.running:
        - enable: True
        - names:
            - mysqld
            - qpidd
            - libvirtd
            - messagebus

nova-db-init:
    cmd.run:
        - name: openstack-db --init --service nova --rootpw ''
        - unless: echo '' | mysql nova
        - require:
            - pkg: openstack-nova
            - service: mysqld

nova-services:
    service.running:
        - enable: True
        - names:
            - openstack-nova-api
            - openstack-nova-objectstore
            - openstack-nova-compute
            - openstack-nova-network
            - openstack-nova-volume
            - openstack-nova-scheduler
            - openstack-nova-cert
        - require:
            - cmd.run: nova-db-init
            - cmd.run: keystone-db-init
            - service.running: openstack-glance-api

keystone-db-init:
    cmd.run:
        - name: openstack-db --init --service keystone --rootpw ''
        - unless: echo '' | mysql keystone
        - require:
            - pkg.installed: openstack-keystone
            - service.running: mysqld

openstack-keystone:
    service.running:
        - enable: True
        - require:
            - pkg.installed: openstack-keystone
        - watch:
            - cmd.run: keystone-db-init

/etc/nova:
    file.recurse:
        - source: salt://openstack/nova
        - require:
            - pkg.installed: openstack-nova
        - watch_in:
            - service: nova-services

/etc/keystone:
    file.recurse:
        - source: salt://openstack/keystone
        - require:
            - pkg.installed: openstack-keystone
        - watch_in:
            - service: openstack-keystone

httpd:
    service.running:
        - enable: True
        - require:
            - pkg.installed: openstack-dashboard
