# Windows Sandbox

> **Windows Sandbox** provides a lightweight desktop environment to safely run applications in isolation. Software installed inside the Windows Sandbox environment remains "sandboxed" and runs separately from the host machine.
>
> A sandbox is **temporary**. When it's closed, all the software and files and the state are **deleted**. You get a brand-new instance of the sandbox every time you open the application.
>
> -- from <cite>[microsoft documentation][1]</cite>

[1]: https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-overview

## Installing Windows Sandbox using PowerShell

Open PowerShell as an administrator

```
Enable-WindowsOptionalFeature -FeatureName "Containers-DisposableClientVM" -All -Online
```

https://adamtheautomator.com/windows-10-sandbox-mode/

```
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

If you feel Windows 10 Hyper-V is affecting your gaming performance or otherwise (without a virtual machine environment running), you can use a command to switch Hyper-V virtualization services off.

```
bcdedit /set hypervisorlaunchtype off
restart
bcdedit /set hypervisorlaunchtype on
```

### Read more

- https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/boot-to-vhd--native-boot--add-a-virtual-hard-disk-to-the-boot-menu?view=windows-11
- https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/learn-more/use-local-resources-on-hyper-v-virtual-machine-with-vmconnect
- https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/manage-hyper-v-scheduler-types#virtual-machine-cpu-resource-controls-and-the-root-scheduler
- https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/deploy-windows-on-a-vhd--native-boot?view=windows-11
