import plistlib, struct, subprocess, sys, tarfile, glob, os
deb = sys.argv[1]
print("file:", subprocess.run(["file", deb], capture_output=True, text=True).stdout.strip())
assert "gzip" in subprocess.run(["file", deb], capture_output=True, text=True).stdout, "deb must be gzip compressed"
listing = subprocess.run(["dpkg-deb", "-c", deb], capture_output=True, text=True).stdout
print(listing)
paths = [l.split()[-1] for l in listing.strip().split("\n")]
for need in ["./Applications/Tube.app/Tube", "./Applications/Tube.app/Info.plist",
             "./Applications/Tube.app/Icon.png", "./Applications/Tube.app/Icon@2x.png",
             "./Applications/Tube.app/Icon-60@2x.png"]:
    assert need in paths, "missing " + need
os.system("rm -rf /tmp/dctrl && mkdir -p /tmp/dctrl")
assert os.system("dpkg-deb -e '%s' /tmp/dctrl" % deb) == 0
assert os.path.isfile("/tmp/dctrl/postinst"), "missing DEBIAN/postinst"
assert os.access("/tmp/dctrl/postinst", os.X_OK), "postinst not executable"
os.system("rm -rf /tmp/ddata && mkdir -p /tmp/ddata")
assert os.system("dpkg-deb --fsys-tarfile '%s' | tar -x -C /tmp/ddata" % deb) == 0
pl = plistlib.load(open("/tmp/ddata/Applications/Tube.app/Info.plist", "rb"))
assert pl["CFBundleExecutable"] == "Tube", pl.get("CFBundleExecutable")
assert pl["CFBundleIdentifier"] == "com.local.tube", pl.get("CFBundleIdentifier")
assert "CFBundleIcons" in pl, "no CFBundleIcons"
b = open("/tmp/ddata/Applications/Tube.app/Tube", "rb").read(64)
assert struct.unpack(">I", b[:4])[0] == 0xcafebabe, "binary is not FAT Mach-O"
n = struct.unpack(">I", b[4:8])[0]
cpus = {struct.unpack(">I", b[8 + i * 20:12 + i * 20])[0] for i in range(n)}
assert 12 in cpus and 16777228 in cpus, "need armv7+arm64 slices, got %s" % cpus
print("verify OK: gzip, layout, postinst, plist, FAT(armv7+arm64)")
