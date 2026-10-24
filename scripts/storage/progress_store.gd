extends RefCounted

## Keep a recoverable previous save and replace only a fully written file.
static func read(path: String) -> ConfigFile:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error == OK:
		return config
	var backup := ConfigFile.new()
	if backup.load(path + ".bak") == OK:
		push_warning("Se recuperó una copia del progreso de %s" % path)
		return backup
	if error != ERR_FILE_NOT_FOUND:
		push_warning("No se pudo leer el progreso de %s" % path)
	return ConfigFile.new()

static func write(config: ConfigFile, path: String) -> Error:
	var temporary := path + ".tmp"
	var error := config.save(temporary)
	if error != OK:
		return error
	var previous := ConfigFile.new()
	if previous.load(path) == OK:
		error = DirAccess.copy_absolute(path, path + ".bak")
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, path)
