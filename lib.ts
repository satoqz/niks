const decoder = new TextDecoder();

const nix = async (...args: string[]): Promise<string> => {
  const command = Deno.run({
    cmd: ["nix", ...args],
    stdout: "piped",
    stderr: "piped",
    stdin: "null",
  });

  const status = await command.status();
  const success = status.code == 0;
  const output = decoder.decode(
    await (success ? command.output() : command.stderrOutput()),
  ).trim();

  if (success) {
    return output;
  } else {
    throw new Error(output);
  }
};

type NixPackage = {
  path: string;
  reference: string;
  index: number;
};

export default class NixProfile {
  private constructor(public readonly packages: Map<string, NixPackage[]>) {}

  public static async init(): Promise<NixProfile> {
    const output = await nix("profile", "list");

    const list = output.split("\n").filter(Boolean).map((row) => {
      const [index, reference, _, path] = row.split(" ");
      return {
        index: parseInt(index),
        reference,
        path,
      };
    }).filter(({ reference }) =>
      reference.startsWith("flake:nixpkgs#legacyPackages")
    );

    const packages = new Map<string, NixPackage[]>();

    for (const pkg of list) {
      const name = pkg.reference.replace(
        /flake:nixpkgs#legacyPackages\.([A-z]|\d|-)*\./,
        "",
      );

      if (!packages.has(name)) {
        packages.set(name, [pkg]);
      } else {
        packages.get(name)!.push(pkg);
      }
    }

    return new NixProfile(packages);
  }

  public has(name: string): boolean {
    return this.packages.has(name);
  }

  public async remove(name: string): Promise<void> {
    const pkgs = this.packages.get(name);

    if (!pkgs || !pkgs.length) {
      throw new Error(`No packages named "${name}" are installed.`);
    }

    const removed: NixPackage[] = [];

    for (const pkg of pkgs) {
      await nix("profile", "remove", pkg.index.toString());
      removed.push(pkg);

      this.packages.forEach((pkgs) =>
        pkgs.filter(({ index }) => index > pkg.index).forEach((pkg) =>
          pkg.index--
        )
      );
    }

    this.packages.set(name, pkgs.filter((pkg) => !removed.includes(pkg)));
  }

  public async install(name: string) {
    if (this.has(name)) {
      throw new Error(`Package ${name} is already installed.`);
    }

    await nix("profile", "install", `nixpkgs#${name}`);
  }

  public async upgrade(name: string) {
    const pkgs = this.packages.get(name);

    if (!pkgs || !pkgs.length) {
      throw new Error(`No packages named "${name}" are installed.`);
    }

    await nix(
      "profile",
      "upgrade",
      ...pkgs.map((pkg) => pkg.index.toString()),
    );
  }
}
