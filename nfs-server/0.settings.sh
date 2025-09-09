sudo apt install nfs-kernel-server
sudo mkdir -p /home/nfs_server


sudo chown -R 1000:1000 /home/nfs_server
sudo chown -R nobody:nogroup /home/nfs_server

sudo vi /etc/exports
>>>
/home/nfs_server   192.169.0.0/16 (rw,sync,no_root_squash,no_subtree_check)

sudo systemctl enable nfs-server
sudo systemctl restart nfs-server
sudo systemctl status nfs-server

sudo exportfs -v

