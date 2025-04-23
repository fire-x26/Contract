import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/zkme_sbt.tact',
    options: {
        debug: true,
    },
};
