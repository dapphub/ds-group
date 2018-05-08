{ solidityPackage, dappsys }: solidityPackage {
  name = "ds-multisig";
  deps = with dappsys; [ds-exec ds-note ds-test];
  src = ./src;
}
