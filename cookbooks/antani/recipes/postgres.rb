#######################
# postgresql and postgis

# Normal install runs initdb without setting the encoding

if not File.directory?( '/var/lib/postgresql/9.1' )

  package 'postgresql-9.1' do
    action :install
  end

  # Repair encoding
  execute 're-create template databases with UTF8 encoding' do
    user 'root'
    command <<-EOT
    pg_dropcluster --stop 9.1 main
    pg_createcluster --encoding=UTF8 --start 9.1 main
    EOT
  end

  [ 'postgresql-9.1-postgis', 'postgresql-server-dev-9.1' ].each do | p |
    package p do
      action :install
    end
  end

  execute 'create postgis_template' do
    user 'postgres'
    command <<-EOT
    createdb -E UTF8 -T template0 template_postgis
    psql -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
    psql -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
    psql -d template_postgis -c "UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';"
    EOT
  end

  template '/etc/postgresql/9.1/main/pg_hba.conf' do
    source 'postgres/pg_hba.conf'
    mode '0644'
  end

  execute 'apply changes to postgresql permissions' do
    user 'root'
    command '/etc/init.d/postgresql restart'
    action :run
  end

end
