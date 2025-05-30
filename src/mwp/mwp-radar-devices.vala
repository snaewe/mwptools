/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * (c) Jonathan Hudson <jh+mwptools@daria.co.uk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Radar {
	const double TOTHEMOON = 999999.0;

	public enum DecType {
		NONE=0,
		PROTOB,
		JSON,
		JSONX,
		PICOJS,
		SBS,
		WS,
	}

	namespace Toast {
		uint id;
		double range;
		Adw.Toast? toast;
	}

	public enum IOType {
		NONE,
		MSER,
		LINE_READER,
		PACKET_READER,
		POLLER,
		WS,
	}

	public class RadarDev : Object {
		public string name {get; set construct;}
		public bool enabled {get; set construct;}
		public Object dev;
		public uint tid;
		public IOType dtype;
		public bool qdel;

		public RadarDev() {
			enabled = false;
			qdel = false;
			tid = 0;
			dtype = IOType.NONE;
		}

		public bool is_enabled() {
			return enabled;
		}
	}

	public GLib.ListStore items;
	public RadarCache radar_cache;
	public RadarView radarv;

	public enum Status {
		UNDEF = 0,
		ARMED = 1,
		HIDDEN = 2,
		STALE = 3,
	}

	public enum AStatus {
		C_MAP=1,
		C_GCS=2,
		C_HOME=3,
		C_VEHICLE=4,
		A_SOUND=8,
		A_TOAST=16,
		A_RED=32
	}

	public enum LateTime {
		STALE = 15,
		HIDE = 30,
		DELETE = 60,
	}


	public bool do_audio;
	public static AStatus astat;
	public static double lat;
	public static double lon;

	 public int cmpfunc (Object a, Object b) {
		 RadarDev ai = (RadarDev)a;
		 RadarDev bi = (RadarDev)b;
		 if (ai.enabled == bi.enabled) {
			 return strcmp(ai.name, bi.name);
		 } else {
			 return (ai.enabled) ? -1 : 1;
		 }
	 }

	public uint8 set_initial_state(uint lq) {
		uint8 state;
		if(lq > Radar.LateTime.HIDE) {
			state = Radar.Status.HIDDEN;
		} else if(lq > Radar.LateTime.STALE) {
			state = Radar.Status.STALE;
		} else {
			state = 0;
		}
		return state;
	}

	private string format_cat(RadarPlot r) {
		if((r.source & RadarSource.M_INAV) != 0) {
			return "B6";
		}
		return CatMap.to_category(r.etype);
	}

	private string format_bearing(RadarPlot r) {
		string ga;
		if (r.bearing == 0xffff) {
			ga = "";
		} else {
			ga = "%u°".printf(r.bearing);
		}
		return ga;
	}

	private string format_range(RadarPlot r) {
		string ga = "";
		if (r.range != TOTHEMOON && r.range != 0.0) {
			if((r.source & RadarSource.M_ADSB) != 0) {
				ga = Units.ga_range(r.range);
			} else {
				ga = "%.0f %s".printf(Units.distance(r.range), Units.distance_units());
			}
		}
		return ga;
	}

	private string format_last(RadarPlot r) {
		if (r.dt != null) {
			return r.dt.format("%T");
		} else {
			return "";
		}
	}

	private string format_status(RadarPlot r) {
		string sstr = "";
		if(r.state == 0) {
			sstr = ((RadarSource)r.source).to_string();
		} else {
			sstr = RadarView.status[r.state];
		}
		return "%s / %u".printf(sstr, r.lq);
	}

	private string format_alt(RadarPlot r) {
		string ga;
		if((r.source & RadarSource.M_ADSB) != 0) {
			ga = Units.ga_alt(r.altitude);
		} else {
			ga = "%.0f %s".printf(Units.distance(r.altitude), Units.distance_units());
		}
		return ga;
	}

	private string format_speed(RadarPlot r) {
		string ga;
		if((r.source & RadarSource.M_ADSB) != 0) {
			ga = Units.ga_speed(r.speed);
		} else {
			ga = "%.0f %s".printf(Units.speed(r.speed), Units.speed_units());
		}
		return ga;
	}

	private string format_course(RadarPlot r) {
		string ga;
		if (r.heading ==  0xffff) {
			ga = "";
		} else {
			ga = "%u°".printf(r.heading);
		}
		return ga;
	}

	public static AStatus set_astatus() {
		astat = 0;
		bool haveloc = GCS.get_location(out lat, out lon); // always wins
		if (haveloc) {
			astat = C_GCS|A_SOUND|A_TOAST|A_RED;
		} else {
			if (Mwp.msp.available && Mwp.msp.td.gps.fix > 1) {
				astat = C_VEHICLE|A_SOUND|A_TOAST|A_RED;
				lat = Mwp.msp.td.gps.lat;
				lon = Mwp.msp.td.gps.lon;
			} else if(HomePoint.is_valid()) {
				haveloc = HomePoint.get_location(out lat, out lon);
				if (haveloc) {
					astat = C_HOME|A_RED;
				}
			}
		}
		if (astat == 0) {
			MapUtils.get_centre_location(out lat, out lon);
			astat = C_MAP;
		}
		return astat;
	}

	public int find_radar(string s) {
		uint np;
		var tmp = new RadarDev();
		tmp.name = s;
		var b = items.find_with_equal_func_full((Object)tmp, (a,b) => {
				return ((RadarDev)a).name == ((RadarDev)b).name;}, out np);
		return (b) ? (int)np : -1;
	}

	public bool lookup_radar(string s) {
		var j = find_radar(s);
		bool res = (j != -1);
		if (res) {
			MWPLog.message("Found radar %s\n", s);
		}
		return res;
	}

	private void queue_remove(RadarDev r) {
		var idx = find_radar(r.name);
		if (idx != -1) {
			items.remove(idx);
		}
	}

	public void add_radar(string pn, bool enable) {
		RadarDev r = new RadarDev();
		r.name = pn;
		var u = UriParser.dev_parse(pn);

		if (u.scheme == "sbs") {
			MWPLog.message("Set up SBS radar device %s\n", pn);
			var sbs = new ADSBReader.net(u);
			sbs.set_dtype(DecType.SBS);
			r.enabled = enable;
			r.dtype = IOType.LINE_READER;
			r.dev = sbs;
			sbs.result.connect((s) => {
					if (s == false) {
						if(r.is_enabled()) {
							r.tid = Timeout.add_seconds(60, () => {
									r.tid = 0;
									sbs.line_reader.begin();
									return false;
								});
						}
						if (r.qdel) {
							queue_remove(r);
						}
					}
				});
			if(r.is_enabled()) {
				sbs.line_reader.begin();
			}
		} else if (u.scheme == "ws") {
			MWPLog.message("Set up WS radar device %s\n", pn);
			var wsa = new ADSBReader.ws(pn);
			r.enabled = enable;
			r.dtype = IOType.WS;
			r.dev = wsa;
			wsa.result.connect((s) => {
					if(r.is_enabled()) {
						int tos = (s) ? 10 : 60;
						r.tid = Timeout.add_seconds(tos, () => {
								r.tid = 0;
								wsa.ws_reader.begin();
								return false;
							});
						if (r.qdel) {
							queue_remove(r);
						}
					}
				});
			if(r.is_enabled()) {
				wsa.ws_reader.begin();
			}
		} else if (u.scheme == "jsa") {
			MWPLog.message("Set up JSA radar device %s\n", pn);
			var jsa = new ADSBReader.net(u, 37007);
			r.enabled = enable;
			r.dtype = IOType.LINE_READER;
			r.dev = jsa;
			jsa.result.connect((s) => {
					if (s == false) {
						if(r.is_enabled()) {
							r.tid = Timeout.add_seconds(60, () => {
									r.tid = 0;
									jsa.line_reader.begin();
									return false;
							});
						}
						if (r.qdel) {
							queue_remove(r);
						}
					}
				});
			if(r.is_enabled()) {
				jsa.line_reader.begin();
			}
		} else if (u.scheme == "pba") {
#if PROTOC
			MWPLog.message("Set up PSA radar device %s\n", pn);
			var pba = new ADSBReader.net(u, 38008);
			pba.set_dtype(DecType.PROTOB);
			r.enabled = enable;
			r.dtype = IOType.PACKET_READER;
			r.dev = pba;

			pba.result.connect((s) => {
					if (s == false) {
						if(r.is_enabled()) {
							r.tid = Timeout.add_seconds(60, () => {
									r.tid = 0;
									pba.packet_reader.begin();
									return false;
							});
						}
						if (r.qdel) {
							queue_remove(r);
						}
					}
				});
			if(r.is_enabled()) {
				pba.packet_reader.begin();
			}
#else
			MWPLog.message("mwp not compiled with protobuf-c\n");
#endif
		} else if (u.scheme == "http" ||
				   u.scheme == "https" ||
				   u.scheme == "adsbx" ) {
			DecType htype = 0;
			if(pn.has_suffix(".pb")) {
				htype = DecType.PROTOB;
			} else if(pn.has_suffix(".json")) {
				htype = DecType.JSON;
			} else if (u.scheme == "adsbx") {
				htype = DecType.JSONX;
			} else if (u.qhash != null) {
				var v = u.qhash.get("source");
				if (v != null && v == "picoadsb") {
					htype = DecType.PICOJS;
				}
			}

			if(htype != 0) {
				MWPLog.message("Set up http %d radar device %s\n", htype, pn);
				ADSBReader httpa;
				if(htype == DecType.JSONX) {
					httpa = new ADSBReader.adsbx(u);
					httpa.set_dtype(DecType.JSONX);
				} else  {
					httpa = new ADSBReader.web(pn);
					httpa.set_dtype(htype);
				}
				r.enabled = enable;
				r.dtype = IOType.POLLER;
				r.dev = httpa;
				httpa.result.connect((s) => {
						if (s == false) {
							if(r.is_enabled()) {
								r.tid = Timeout.add_seconds(60, () => {
										r.tid = 0;
										httpa.poll();
										return false;
									});
							}
							if (r.qdel) {
								queue_remove(r);
							}
						}
					});
				if(r.is_enabled()) {
					httpa.poll();
				}
			}
		} else {
			MWPLog.message("Set up radar device %s\n", r.name);
			var ser =  new MWSerial();
			r.dev =  ser;
			r.dtype = IOType.MSER;
			r.enabled = enable;
			if (u.qhash != null) {
				var v = u.qhash.get("mavlink");
				if (v != null) {
					uint8 mvers = (uint8)uint.parse(v);
					if(mvers < 1)
						mvers = 1;
					if(mvers > 2)
						mvers = 2;
					ser.mavvid = mvers;
				}
			}
			ser.set_mode(MWSerial.Mode.SIM);
			ser.set_pmask(MWSerial.PMask.INAV);
			ser.serial_event.connect(()  => {
					MWSerial.INAVEvent? m;
					while((m = ser.msgq.try_pop()) != null) {
						MspRadar.handle_radar(ser, m.cmd,m.raw,m.len,m.flags,m.err);
					}
				});

			ser.serial_lost.connect(() => {
					MWPLog.message(":DBG: Radar IOSER %s closed\n", r.name);
				});

			try_radar_dev(r);
		}
		items.insert_sorted(r, cmpfunc);
	}

	public void update_active(int j, bool  active, bool qdel = false) {
		var r = items.get_item(j) as RadarDev;
		bool prev = r.enabled;
		r.enabled = active;
		if (!active) {
			if (r.tid > 0) {
				Source.remove(r.tid);
				r.tid = 0;
			}
			if (r.dtype == IOType.MSER) {
				((MWSerial)r.dev).close_async.begin((obj,res) => {
						((MWSerial)r.dev).close_async.end(res);
					});

				if (qdel) {
					 Radar.items.remove(j);
				 }
			} else {
				if (prev) {
					r.qdel = qdel;
					if(r.dtype == IOType.WS) {
						((ADSBReader)r.dev).ws_cancel();
					} else {
						((ADSBReader)r.dev).cancel();
					}
				} else {
					Radar.items.remove(j);
				}
			}
		} else {
			switch(r.dtype) {
			case IOType.MSER:
				try_radar_dev(r);
				break;
			case IOType.LINE_READER:
				((ADSBReader)r.dev).line_reader.begin();
				break;
			case IOType.PACKET_READER:
				((ADSBReader)r.dev).packet_reader.begin();
				break;
			case IOType.POLLER:
				((ADSBReader)r.dev).poll();
				break;
			case IOType.WS:
				((ADSBReader)r.dev).ws_reader.begin();
				break;
			default:
				break;
			}
		}
	}

	public void init() {
		radar_cache = new Radar.RadarCache();
		do_audio = (Mwp.conf.radar_alert_range > 0 && Mwp.conf.radar_alert_altitude > 0);
		radarv = new RadarView();
		Radar.init_icons();
		items = new GLib.ListStore(typeof(RadarDev));
	}

	public void init_readers() {
		foreach (var rd in Mwp.radar_device) {
			var parts = rd.split(",");
			foreach(var p in parts) {
				var pn = p.strip();
				add_radar(pn, true);
			}
		}
		read_cmdopts();
		dump_radars();
		Timeout.add_seconds(2, () => {
				radar_periodic();
				return true;
			});
	}

	private void dump_radars() {
		if(Mwp.DebugFlags.RDRLIST in Mwp.debug_flags) {
			var sb = new StringBuilder(":DBG: Radar list\n");
			for (var i = 0; i < items.get_n_items(); i++) {
				var r = items.get_item(i) as RadarDev;
				sb.append_printf("\t%s %s %s\n", r.name, r.enabled.to_string(), r.dtype.to_string());
			}
			MWPLog.message(sb.str);
		}
	}

    private void try_radar_dev(RadarDev r) {
		if (r.enabled && r.dtype == IOType.MSER) {
			if(!((MWSerial)r.dev).available) {
				((MWSerial)r.dev).open_async.begin(r.name, 0, (obj,res) => {
						var ok = ((MWSerial)r.dev).open_async.end(res);
						if (ok) {
							((MWSerial)r.dev).setup_reader();
							MWPLog.message("start radar reader %s\n", r.name);
							if(((MWSerial)r.dev).mavvid != 0) {
								Mav.send_mav_beacon((MWSerial)r.dev);
							}
						} else {
						string fstr;
						((MWSerial)r.dev).get_error_message(out fstr);
						MWPLog.message("Radar reader %s\n", fstr);
						r.tid = Timeout.add_seconds(15, () => {
								r.tid = 0;
								try_radar_dev(r);
								return false;
							});
						}
					});
			}
		}
	}

	public void read_cmdopts() {
		var fn = MWPUtils.find_conf_file("cmdopts");
		if(fn != null) {
			var fs = FileStream.open(fn, "r");
			if (fs != null) {
				string line;
				while ((line = fs.read_line()) != null) {
					line = line.strip();
					var pfx = line.index_of("--radar-device");
					if (pfx != -1) {
						var enabled = (pfx == 0);
						pfx += "--radar-device".length;
						while (line[pfx] == ' ' || line[pfx] == '=' ) {
							pfx++;
						}
						var uri = line[pfx:];
						var k = find_radar(uri);
						if (k  != -1) {
							var r = items.get_item(k) as RadarDev;
							r.enabled = (enabled);
						} else {
							add_radar(uri, enabled);
						}
					}
				}
			}
		}
	}

	public void write_out() {
		var fn = MWPUtils.find_conf_file("cmdopts");
        var bfn = "%s.bak".printf(fn);
        if(FileUtils.rename(fn, bfn) == 0) {
            var ifs = FileStream.open(bfn, "r");
            var ofs = FileStream.open(fn, "w");
            if (ifs != null && ofs != null) {
                string line;
                bool seen = false;
                while ((line = ifs.read_line()) != null) {
                    if(!line.contains("--radar-device")) {
                        ofs.puts(line);
                        ofs.putc('\n');
                    } else if(!seen) {
                        write_file(ofs);
                        seen = true;
                    }
                }

                if(!seen) {
                    write_file(ofs);
                }
            }
        }
	}

	private void write_file(FileStream ofs) {
		items.sort(cmpfunc);
		for (var i = 0; i < items.get_n_items(); i++) {
			var r = items.get_item(i) as RadarDev;
			if(!r.enabled) {
				ofs.puts("# ");
			}
			ofs.printf("--radar-device %s\n", r.name);
		}
	}

}
