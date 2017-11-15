dapp: with dapp; solidityPackage {
  name = "ds-group";
  deps = with dappsys; [ds-exec ds-note ds-test];
  src = ./src;
}
