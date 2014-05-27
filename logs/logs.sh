#----------------------Start of Script------------------#

function die () {
    echo >&2 "$@"
    exit 1
}

CONFIG=${1:-`dirname $0`/logs.conf}
[ -f "$CONFIG" ] && . "$CONFIG" || die "No se puede leer ${CONFIG}!"

if  [ ! -d $LOGSDIR ]; then
	echo -n "Creando $LOGSDIR..."
	mkdir -p $LOGSDIR
	echo "Listo!"
fi

echo "Realizando copia de los logs..."
tar czfv $LOGSDIR/$SERVER-$DATE-logs.tar.gz $CRASHDIR $LOGDIR

if  [ $DELETE = "y" ]; then
	OLDDBS=`cd $LOGSDIR; find . -name "*-logs.tar.gz" -mtime +$DAYS`
	REMOVE=`for file in $OLDDBS; do echo -n -e "delete ${file}\n"; done`
		
	cd $LOGSDIR; for file in $OLDDBS; do rm -v ${file}; done
	if  [ $DAYS = "1" ]; then
		echo "Logs de ayer borrados."
	else
		echo "Logs de hace $DAYS borrados."
	fi
fi
	
if  [ $FTP = "y" ]; then
	echo "Iniciando conexion FTP..."

	cd $LOGSDIR
	ATTACH=`for file in *$DATE-logs.tar.gz; do echo -n -e "put ${file}\n"; done`

	for KEY in "${!FTPHOST[@]}"; do
		echo -e "\nConnecting to ${FTPHOST[$KEY]} with user ${FTPUSER[$KEY]}..."
		ftp -nvp <<EOF
	open ${FTPHOST[$KEY]}
	user ${FTPUSER[$KEY]} ${FTPPASS[$KEY]}
	tick
	mkdir ${FTPDIR[$KEY]}
	cd ${FTPDIR[$KEY]}
	$REMOVE
	$ATTACH
	quit
EOF
		done

	echo -e  "Transferencia FTP completa. \n"
fi

echo "Logs subidos de forma correcta."

