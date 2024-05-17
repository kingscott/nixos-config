{ pkgs ? import <nixpkgs> {} }:
 
 (pkgs.buildFHSUserEnv {
   name = "bazel-userenv-kingscott";
   targetPkgs = pkgs: [
     pkgs.bazel
     pkgs.glibc
     pkgs.gcc
   ];
 }).env
