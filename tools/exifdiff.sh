exifdiff () {
	delta <(exiftool "$1") <(exiftool "$2")
}
