mpe_dir = meson.current_source_dir()
mpe_files = files('dem.go','gnuplot.go','main.go','mission.go','rework.go',
                  'utils.go', 'los.go', 'localdem.go', 'dem-download.go')
if build_machine.system() == 'windows'
  mpe_files += files('silent_windows.go')
else
  mpe_files += files('silent_other.go')
endif
